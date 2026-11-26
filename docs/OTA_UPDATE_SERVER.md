# 한돌이 OTA 업데이트 서버 (update.handol.app) 구축 요청서

> 이 문서는 서버 구축을 맡은 에이전트에게 넘기는 것이다. 앱 쪽 작업(한돌이 RN 앱, handol-rn)은 끝났고, 여기 적힌 대로 서버만 만들면 된다.
> 작성: 2026-11-26. 기준: Expo SDK 58, expo-updates 프로토콜 v1.

## 1. 무엇을 만드나

한돌이 앱(Android `app.handol.student`, React Native/Expo)은 실행할 때마다 아래 주소에 "새 JS 번들이 있나"를 묻는다. 있으면 몰래 받아 두었다가 **다음 실행부터** 적용한다(사용자는 기다리지 않는다).

```
GET https://update.handol.app/api/manifest
```

서버가 할 일은 두 가지뿐이다.

1. `GET /api/manifest` — 요청 헤더의 플랫폼·런타임 버전에 맞는 **가장 최근 매니페스트**를 정해진 형식(multipart)으로 돌려준다. 없으면 204.
2. `GET /files/<이름>` — 번들·이미지 파일을 정적으로 내려준다.

매니페스트와 파일은 **개발자 PC에서 미리 만들고 서명까지 해서** 서버 데이터 폴더에 올린다(5장). 서버는 서명 개인키를 갖지 않고, 빌드도 하지 않는다. 파일을 읽어서 내보내기만 한다.

### 바꾸면 안 되는 것

| 항목 | 값 | 이유 |
|---|---|---|
| 도메인 | `update.handol.app` | 앱 바이너리에 박혀 있다. 바꾸면 이미 깔린 앱은 영영 업데이트를 못 받는다(스토어 재배포 필요). 서버를 옮겨도 **도메인은 유지**하고 DNS/프록시만 바꾼다. |
| 매니페스트 경로 | `/api/manifest` | 위와 같다 |
| 파일 경로 | `/files/<이름>` | 매니페스트 안의 URL이 `https://update.handol.app/files/...` 로 만들어진다 |
| HTTPS | 필수 | Android 릴리스 빌드는 평문 HTTP를 막는다. 유효한 공인 인증서(Let's Encrypt 등) 필요 |

## 2. 프로토콜 (expo-updates v1 중 우리가 쓰는 부분)

### 요청 (앱 → 서버)

```
GET /api/manifest
expo-protocol-version: 1
expo-platform: android            # 또는 ios
expo-runtime-version: 0.3.20      # 앱 버전(versionName)과 같다
expo-current-update-id: <uuid>    # 지금 실행 중인 업데이트 id (처음엔 앱에 내장된 번들 id)
expo-embedded-update-id: <uuid>
expo-expect-signature: sig, keyid="main", alg="rsa-v1_5-sha256"
accept: multipart/mixed, application/expo+json, application/json
a-im: bsdiff                      # 무시해도 된다(전체 파일을 주면 됨)
```

### 응답 A — 업데이트 있음 (200)

헤더:

```
expo-protocol-version: 1
expo-sfv-version: 0
cache-control: private, max-age=0
content-type: multipart/mixed; boundary=<임의 문자열>
```

본문(줄바꿈은 모두 `\r\n`):

```
--<boundary>
content-type: application/json; charset=utf-8
content-disposition: form-data; name="manifest"
expo-signature: <저장된 signature 값 그대로>

<저장된 manifest 문자열 그대로>
--<boundary>--
```

**중요: manifest 문자열은 한 바이트도 바꾸면 안 된다.** 앱이 이 바이트열 그대로 RSA 서명을 검증한다. JSON을 파싱했다가 다시 직렬화하거나, 공백·줄바꿈을 넣거나, 압축 미들웨어가 내용을 바꾸면 서명 검증이 실패하고 앱은 업데이트를 버린다. (전송 압축 gzip 자체는 괜찮다. 내용이 복원되므로.)

### 응답 B — 업데이트 없음 (204)

```
HTTP 204
expo-protocol-version: 1
expo-sfv-version: 0
cache-control: private, max-age=0
```

다음 경우 204를 준다.
- 그 런타임 버전·플랫폼에 올라간 매니페스트가 없다.
- 최신 매니페스트의 id가 요청의 `expo-current-update-id`와 같다(이미 최신).

### 잘못된 요청 (400)

`expo-platform`이 android/ios가 아니거나 `expo-runtime-version`이 없거나 `[A-Za-z0-9._-]` 밖의 문자가 있으면 400. **런타임 버전은 경로에 쓰이므로 반드시 이 정규식으로 걸러야 한다(경로 조작 방지).**

## 3. 데이터 폴더 구조

개발자가 올려 주는 폴더(예: `/srv/handol-updates`)는 이렇게 생겼다. 서버는 이 구조를 읽기만 한다.

```
/srv/handol-updates/
├─ manifests/
│  └─ <runtimeVersion>/            # 예: 0.3.20
│     └─ <platform>/               # android | ios
│        ├─ 1795620669656-42085bcf-....json
│        └─ 1795700000000-9a1c....json   ← 파일명 사전순 마지막 = 최신
└─ files/
   ├─ <sha256-base64url>.hbc       # JS 번들
   └─ <sha256-base64url>.png       # 이미지 등
```

- 매니페스트 파일명: `<생성시각 ms 13자리>-<업데이트 uuid>.json`. 이름순 정렬 = 시간순이다.
- 매니페스트 파일 내용: `{"manifest": "<서명된 JSON 문자열>", "signature": "sig=\"<base64>\", keyid=\"main\""}`
  - `manifest` 값은 문자열이다. 그대로 응답 본문에 넣는다.
  - `signature` 값은 그대로 `expo-signature` 헤더에 넣는다.
- `files/`의 파일명은 내용의 SHA-256이라 **절대 바뀌지 않는다**. 영구 캐시해도 되고 CDN에 올려도 된다. 지우지 말 것(이전 업데이트를 받은 앱이 아직 참조할 수 있다).

참고로 manifest 문자열을 파싱하면 이런 모양이다(서버가 해석할 필요는 `id` 말고 없다):

```json
{
  "id": "42085bcf-d9f6-493a-a035-ebe2727a6ac9",
  "createdAt": "2026-11-25T15:31:09.656Z",
  "runtimeVersion": "0.3.20",
  "launchAsset": { "hash": "...", "key": "...", "contentType": "application/javascript", "fileExtension": ".hbc", "url": "https://update.handol.app/files/<hash>.hbc" },
  "assets": [ { "hash": "...", "key": "...", "contentType": "image/png", "fileExtension": ".png", "url": "https://update.handol.app/files/<hash>.png" } ],
  "metadata": {},
  "extra": { "expoClient": { "...": "앱 설정" } }
}
```

## 4. 참고 구현 (Node 20+, 의존성 없음)

아래 코드는 앱 저장소에서 실제 배포물로 검증했다: 200 응답의 서명이 앱 인증서로 검증됨, 47개 파일 해시 전부 일치, 이미 최신이면 204, 없는 런타임 버전 204, `../x` 런타임 버전 400, 경로 조작 파일 요청 404.
그대로 써도 되고, 다른 언어로 옮겨도 된다(2장의 규칙만 지키면 됨).

```js
// update.handol.app OTA 서버 (expo-updates 프로토콜 v1). 의존성 없음, Node 20+.
//   DATA_DIR=/srv/handol-updates PORT=3000 node server.mjs
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const DATA = path.resolve(process.env.DATA_DIR ?? './data');
const PORT = Number(process.env.PORT ?? 3000);
const SAFE = /^[A-Za-z0-9._-]+$/;
const TYPES = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.webp': 'image/webp', '.xml': 'application/xml', '.ttf': 'font/ttf', '.otf': 'font/otf', '.json': 'application/json', '.mp4': 'video/mp4', '.hbc': 'application/javascript' };

/** <runtime>/<platform> 폴더에서 가장 최근 매니페스트. 파일명이 "<ms>-<id>.json" 이라 이름순 = 시간순 */
function latest(runtime, platform) {
  const dir = path.join(DATA, 'manifests', runtime, platform);
  if (!fs.existsSync(dir)) return null;
  const names = fs.readdirSync(dir).filter((n) => n.endsWith('.json')).sort();
  return names.length ? JSON.parse(fs.readFileSync(path.join(dir, names.at(-1)), 'utf8')) : null;
}

function manifest(req, res) {
  const platform = req.headers['expo-platform'];
  const runtime = req.headers['expo-runtime-version'];
  if ((platform !== 'android' && platform !== 'ios') || !runtime || !SAFE.test(runtime)) {
    res.writeHead(400).end('expo-platform / expo-runtime-version 헤더가 필요합니다');
    return;
  }
  const base = { 'expo-protocol-version': '1', 'expo-sfv-version': '0', 'cache-control': 'private, max-age=0' };
  const update = latest(runtime, platform);
  // 업데이트가 없거나 이미 그 업데이트를 쓰고 있으면 204 (프로토콜 v1)
  if (!update || JSON.parse(update.manifest).id === req.headers['expo-current-update-id']) {
    res.writeHead(204, base).end();
    return;
  }
  const boundary = 'handol-' + Date.now().toString(36);
  const body =
    '--' + boundary + '\r\n' +
    'content-type: application/json; charset=utf-8\r\n' +
    'content-disposition: form-data; name="manifest"\r\n' +
    'expo-signature: ' + update.signature + '\r\n\r\n' +
    update.manifest + '\r\n' +
    '--' + boundary + '--\r\n';
  res.writeHead(200, { ...base, 'content-type': 'multipart/mixed; boundary=' + boundary }).end(body);
}

function file(name, res) {
  const full = path.join(DATA, 'files', name);
  if (!SAFE.test(name) || !fs.existsSync(full)) {
    res.writeHead(404).end();
    return;
  }
  // 파일명이 내용 해시라 영구 캐시해도 된다
  res.writeHead(200, { 'content-type': TYPES[path.extname(name)] ?? 'application/octet-stream', 'cache-control': 'public, max-age=31536000, immutable' });
  fs.createReadStream(full).pipe(res);
}

http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  if (req.method !== 'GET') res.writeHead(405).end();
  else if (url.pathname === '/api/manifest') manifest(req, res);
  else if (url.pathname.startsWith('/files/')) file(url.pathname.slice('/files/'.length), res);
  else if (url.pathname === '/health') res.writeHead(200).end('ok');
  else res.writeHead(404).end();
}).listen(PORT, () => console.log('OTA server :' + PORT + ' data=' + DATA));
```

## 5. 배포 흐름 (참고: 앱 개발자 쪽)

1. 앱 개발자가 PC에서 `node scripts/publish-update.mjs android` 를 실행한다.
   - JS 번들을 export → 파일을 `updates-out/files/`에 해시 이름으로 복사 → 매니페스트를 개인키로 서명 → `updates-out/manifests/<rv>/<platform>/`에 저장.
2. `updates-out/` 을 서버 데이터 폴더에 **덮어 합친다**(기존 파일 삭제 없이). 예:
   ```
   rsync -av updates-out/ deploy@<서버>:/srv/handol-updates/
   ```
3. 끝. 서버 재시작 필요 없음(요청마다 폴더를 읽는다).

**서버 쪽에 필요한 것**: 이 업로드를 받을 방법(SSH 계정 + 데이터 폴더 쓰기 권한 등). 어떤 방식으로 올리면 되는지 앱 개발자에게 알려 줄 것.

업로드 순서 주의: rsync는 `files/`와 `manifests/`를 함께 올리지만, 다른 방법을 쓴다면 **files를 먼저, manifests를 나중에** 올린다. 매니페스트가 먼저 보이면 앱이 아직 없는 파일을 받으려다 실패한다(실패해도 다음 실행에 다시 시도하므로 치명적이진 않다).

## 6. 인프라 권장 구성

- 리버스 프록시(nginx/Caddy/Nginx Proxy Manager 등)가 TLS를 끝내고 Node 서버(예: 127.0.0.1:3000)로 넘긴다.
- `/files/`는 프록시가 데이터 폴더에서 직접 정적 서빙해도 된다(`/srv/handol-updates/files/`, `Cache-Control: public, max-age=31536000, immutable`).
- **`/api/manifest`는 프록시·CDN이 절대 캐시하면 안 된다.** 요청 헤더마다 응답이 다르다. Cloudflare를 쓴다면 이 경로는 캐시 우회 규칙을 건다.
- 프록시가 응답 본문을 고치지 않게 한다(본문 재작성·HTML 최적화 기능 끄기). 2장 "중요" 참고.
- 요청 헤더(`expo-*`)가 프록시에서 지워지지 않게 한다. 밑줄 없는 소문자 헤더라 보통 문제없다.
- 프로세스 관리: systemd 또는 pm2로 자동 재시작. `GET /health` → `ok` 로 헬스체크.
- 크기: 업데이트 한 번에 약 5~6MB(번들 5.1MB + 이미지). 디스크는 넉넉히 수 GB면 충분.

nginx 예시:

```nginx
server {
  listen 443 ssl http2;
  server_name update.handol.app;
  # ssl_certificate ... (Let's Encrypt)

  location /files/ {
    alias /srv/handol-updates/files/;
    add_header Cache-Control "public, max-age=31536000, immutable";
  }
  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_buffering off;
    add_header Cache-Control "private, max-age=0" always;
  }
}
```

## 7. 보안

- 서버는 **서명 개인키를 받지 않는다.** 앱에는 공개 인증서만 들어 있고, 서명이 맞지 않는 매니페스트는 앱이 거부한다. 서버가 털려도 악성 번들을 심을 수 없다(최악은 업데이트를 못 받게 하는 것).
- 그래도 데이터 폴더 쓰기 권한은 배포 계정 하나로 제한한다.
- 런타임 버전 헤더·파일 이름은 `^[A-Za-z0-9._-]+$`로 거른다(참고 구현에 있음).
- GET 외 메서드는 405.

## 8. 되돌리기(롤백)

앱은 **현재보다 createdAt이 최신인** 업데이트만 받는다. 그래서 최신 매니페스트 파일을 지워도 이미 받은 앱은 되돌아가지 않는다.

- 정상 롤백: 앱 개발자가 이전 코드로 다시 `publish-update.mjs`를 실행해 **새** 매니페스트로 올린다.
- 긴급히 더 퍼지는 것만 막기: 문제 매니페스트 파일을 지우면 아직 못 받은 기기에는 안 간다.

## 9. 완료 확인 (서버 담당이 할 것)

```bash
# 1) 헬스체크
curl -s https://update.handol.app/health                 # ok

# 2) 업데이트 없음 → 204
curl -s -o /dev/null -w '%{http_code}\n' https://update.handol.app/api/manifest \
  -H 'expo-protocol-version: 1' -H 'expo-platform: android' -H 'expo-runtime-version: 0.0.0'   # 204

# 3) 잘못된 런타임 → 400
curl -s -o /dev/null -w '%{http_code}\n' https://update.handol.app/api/manifest \
  -H 'expo-platform: android' -H 'expo-runtime-version: ../etc'                              # 400

# 4) 앱 개발자가 첫 배포물을 올린 뒤 → 200 multipart, expo-protocol-version: 1 헤더
curl -si https://update.handol.app/api/manifest \
  -H 'expo-protocol-version: 1' -H 'expo-platform: android' -H 'expo-runtime-version: 0.3.20' | head -20

# 5) 매니페스트 안의 launchAsset.url 을 받아 200 인지
```

끝나면 앱 개발자에게 알려 줄 것:
- 서버 주소가 살아 있음(1~3번 결과)
- 배포물 업로드 방법(호스트, 계정, 데이터 폴더 경로)

## 10. 구축 결과 (2026-11-26)

| 항목 | 값 |
|---|---|
| 서버 | 사무실 CT 195 `rn-ota` (Ubuntu 25.04, Node 20.18), systemd `handol-ota` :3000 |
| 접속 | `ssh office-ct195` (Warpgate 중계) |
| 데이터 | `/srv/handol-updates` (소유 `deploy`, 서버는 읽기만) |
| 프록시·인증서 | 사무실 NPMplus, Let's Encrypt 자동 갱신 |
| DNS | Cloudflare, DNS only(프록시 끔: 캐시·본문 변경 방지) |

배포 (handol-rn 폴더, Git Bash):

```bash
node scripts/publish-update.mjs android
tar -C updates-out -cf - files     | ssh office-ct195 "runuser -u deploy -- tar -x --no-same-owner -C /srv/handol-updates"
tar -C updates-out -cf - manifests | ssh office-ct195 "runuser -u deploy -- tar -x --no-same-owner -C /srv/handol-updates"
```

로그는 `ssh office-ct195 journalctl -u handol-ota -f`.
