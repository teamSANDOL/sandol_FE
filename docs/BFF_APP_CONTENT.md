# BFF 개발 요청: 앱 콘텐츠 서버

> 요청: 한돌이 앱 FE · 작성 2026-11-24 · 수정 2026-11-24(React Native 이식에 맞춰 5장을 OTA 업데이트로 바꿈), 2026-11-25(7장 푸시 알림 추가)
> · 관련 문서 [DYNAMIC_ASSETS.md](DYNAMIC_ASSETS.md), [handol-rn/MIGRATION_GUIDE.md](../handol-rn/MIGRATION_GUIDE.md)

## 1. 왜 필요한가

홈 광고, 서비스 공지, 스플래시·로고 같은 **앱에만 있는 콘텐츠**가 지금은 앱 안에
들어 있거나 아예 없다. 하나를 바꾸려 해도 빌드, 배포, 사용자 업데이트를 다 거쳐야 하고,
그동안 지난 내용이 계속 보인다(지금 홈 광고도 이미 끝난 2026-09 축제다).

BFF(앱 전용 서버)가 이 콘텐츠를 내려 주면 운영자가 앱 업데이트 없이 바꿀 수 있다.

**가장 중요한 것은 5장 패시브 업데이트다.** 앱을 Flutter에서 React Native(Expo,
`handol-rn/`)로 옮기는 가장 큰 이유가 이것이다. RN 앱은 화면 코드(JS 번들)와 그림을
서버에서 받아 **다음 실행부터** 바꿀 수 있다. 스토어 심사와 사용자의 수동 업데이트 없이
버그 수정, 문구·디자인 변경, 새 화면까지 내보낼 수 있다. BFF가 이 업데이트 서버
(Expo Updates 프로토콜)를 맡아 달라.

## 2. 용어: 두 가지 공지

| | 학교 공지 | 서비스 공지 |
|---|---|---|
| 내용 | 학교 홈페이지 공지(학사, 장학, 셔틀 등) | 한돌이 운영 공지(점검, 업데이트, 새 기능, 약관 변경) |
| 쓰는 사람 | 학교 | 한돌이 운영팀 |
| 앱 위치 | 하단 「공지」 탭(`/notice`) | **화면 없음**. 메뉴 자리(마이 > 고객 지원 > 공지사항)만 있다 |
| 서버 | 기존 공지 API(이번 범위 아님) | **이번 요청** |

> 지금 앱은 마이 > 공지사항을 누르면 학교 공지 탭으로 간다
> (Flutter `lib/features/user/presentation/page/user_page.dart:116`, RN도 같다). 서비스 공지 API가 생기면
> 서비스 공지 화면으로 바꾼다.

## 3. 범위

| 우선순위 | 대상 | 앱 위치(지금) | 적용 시점 |
|---|---|---|---|
| **P0(최우선)** | **앱 OTA 업데이트(JS 번들·그림)** | 없음. 지금은 스토어 배포만 | **다음 실행부터**(5장, 패시브 업데이트) |
| P0 | 홈 맨 위 배너(광고·기능 소개) | `handol-rn/src/features/home/banners.ts` | 받은 즉시 |
| P0 | 서비스 공지(목록·상세) | 화면 없음. 마이 > 공지사항 메뉴만 있고 지금은 학교 공지로 연결됨 | 받은 즉시 |
| P0 | 긴급 점검 안내 | 없음 | 앱을 켤 때 |
| — | 브랜드 에셋(스플래시 영상·포스터, 로고), 앱 안 아이콘 | `handol-rn/src/design-system/assets.ts` | 5장 OTA 업데이트에 포함. **별도 API 필요 없음** |
| P0 | 푸시 알림(기기 등록·발송) | 앱 쪽 완료(`handol-rn/src/features/push/`). 서버 없음 | 등록 즉시(7장) |
| P1 | 자주 묻는 질문, 서비스 안내 | 마이 > 고객 지원(지금 「준비 중」) | 받은 즉시 |

이번 범위가 **아닌** 것:

- 학교 공지, 학식, 셔틀, 빈 강의실: 이미 있는 데이터 API를 쓴다.
- 앱 런처 아이콘(홈 화면 아이콘), OS 시작 화면(JS가 뜨기 전 한 장), 권한·네이티브 모듈 추가:
  OS가 설치 파일에서만 읽으므로 OTA로도 바꿀 수 없다. 스토어 배포로 한다(5.4).
- 카카오·구글·애플 로그인 버튼 그림: 각 회사 브랜드 규정에 맞춘 고정 그림이다.
  규정이 바뀔 때만 손대므로 앱 업데이트로 충분하다.

## 4. 홈 배너·점검 안내

### 4.1 한 번에 받기

```
GET /app/v1/contents?platform=android&app_version=0.3.18&build=3018
```

- 인증 없음(공개). 둘러보기 사용자도 같은 응답을 받는다.
- 앱을 켤 때 한 번, 홈에서 당겨서 새로고침할 때 한 번 부른다.
- 서버가 게시 기간, 플랫폼, 앱 빌드로 **걸러서** 지금 보일 것만 준다.

응답 `200`:

```json
{
  "home_banners": [
    {
      "id": "festival-2026",
      "kind": "image",
      "title": "Techno Festival 2026.09.29 ~ 2026.10.01",
      "body": null,
      "image_url": "https://cdn.example/app/banner/festival-2026@3x.jpg",
      "icon_url": null,
      "link": "https://instagram.com/...",
      "starts_at": "2026-09-01T00:00:00+09:00",
      "ends_at": "2026-10-01T23:59:59+09:00"
    },
    {
      "id": "feature-bus",
      "kind": "text",
      "title": "셔틀, 다음 출발까지",
      "body": "정왕역·제2캠퍼스 셔틀 시간표를 바로 봐요",
      "image_url": null,
      "icon_url": "https://cdn.example/app/icon/bus.svg",
      "link": "/bus",
      "starts_at": null,
      "ends_at": null
    }
  ],
  "maintenance": null,
  "min_supported_build": 3018
}
```

- `maintenance`: 점검 중이거나 예정이면
  `{"message": "...", "starts_at": "...", "ends_at": "...", "blocking": true}`.
  `blocking`이 true면 앱은 안내 화면만 보여 주고, false면 한 번 띄우고 닫게 한다.
- `min_supported_build`: 이 빌드보다 낮은 설치본은 「스토어에서 업데이트」 화면만 보인다.
  OTA로 고칠 수 없는 문제(네이티브 버그, 서버 API 폐기)에 쓴다. null이면 제한 없음.

### 4.2 배너 필드

| 필드 | 형식 | 필수 | 의미 / 규칙 |
|---|---|---|---|
| `id` | string | O | 배너 고유 값. 같은 배너를 고치면 그대로 둔다 |
| `kind` | `"image"` \| `"text"` | O | image: 글자까지 그린 그림 한 장. text: 앱이 제목·설명·아이콘을 그린다 |
| `title` | string | O | text는 제목(한 줄). image는 **화면 읽기(접근성)용 문구**라 그림 속 글자를 그대로 적는다 |
| `body` | string \| null | | text의 설명(최대 2줄, 약 30자) |
| `image_url` | string \| null | image면 O | 그림 주소 |
| `icon_url` | string \| null | | text 오른쪽 아이콘. 단색 SVG(앱이 흰색으로 칠함) |
| `link` | string \| null | | 4.3 참고. null이면 눌리지 않는다 |
| `starts_at`, `ends_at` | ISO 8601(+09:00) \| null | | 게시 기간. null은 제한 없음 |

- 배열 순서가 곧 화면 순서다. 배열이 비면 앱은 그 자리를 숨긴다.
- 배너 하나의 형식이 틀리면 앱은 그 배너만 버린다. 모르는 `kind`나 필드는 무시한다.
- 서버 실패 때는 마지막으로 받은 응답, 그것도 없으면 앱 내장 목록을 쓴다. 저장본을
  쓸 때는 `ends_at`이 지난 배너를 앱이 뺀다.

### 4.3 `link` 규칙

문자열 하나로 갈 곳을 정한다. 앱은 이미 이 규칙으로 되어 있다
(`handol-rn/src/features/home/model.ts` `parseBannerLink`).

| 값 | 동작 | 예 |
|---|---|---|
| `https://...` | 외부 브라우저 | 학생회 인스타그램 |
| `/경로` | 앱 화면(쿼리 가능) | `/meal`, `/bus`, `/home/organization` |
| null | 눌리지 않음 | |

- 앱 화면은 **앱이 허용한 경로만** 연다. 지금 허용 목록: `/home`, `/meal`, `/bus`,
  `/notice`, `/map`, `/home/organization`, `/user`, `/user/announcements`, `/user/faq`, `/user/guide`.
- 메뉴에 없는 **숨은 화면**은 앱이 라우터와 허용 목록에 먼저 넣어 배포한 뒤 서버가
  그 경로를 내린다. 그보다 옛 앱에는 `min_app_build`(4.4)로 안 보이게 한다.
- `http://`, `javascript:`, `intent:`, 허용 목록에 없는 경로는 앱이 무시한다.
  서버도 입력 단계에서 막아 달라.

### 4.4 버전·플랫폼 조건

배너마다 운영 화면에서 `platforms`(android·ios)와 `min_app_build`·`max_app_build`를
정하게 해 달라. 응답에는 걸러진 결과만 준다.

## 5. 패시브 업데이트(OTA): 최우선

### 5.1 동작

앱은 [Expo Updates 프로토콜 v1](https://docs.expo.dev/technical-specs/expo-updates-1/)
클라이언트(`expo-updates`)를 쓴다. BFF는 그 **서버 쪽**을 구현한다.

1. 앱을 켜면 가지고 있는 번들로 **바로 뜬다**(`fallbackToCacheTimeout: 0`, 기다리지 않음).
2. 동시에 뒤에서 서버에 새 업데이트가 있는지 묻고, 있으면 받아 둔다.
3. **다음 실행부터** 새 번들로 뜬다. 사용자는 아무것도 누르지 않는다.
4. 받기·검증에 실패하면 지금 번들을 계속 쓴다. 새 번들이 뜨자마자 죽으면 앱이
   스스로 직전 번들로 돌아간다(expo-updates 기본 동작).

```
GET /app/v1/updates/manifest
expo-protocol-version: 1
expo-platform: android            # 또는 ios
expo-runtime-version: 0.3.18      # 5.4
expo-channel-name: production     # production | staging
expo-current-update-id: <uuid>    # 지금 돌고 있는 업데이트
expo-embedded-update-id: <uuid>   # 설치 파일에 들어 있던 업데이트
expo-expect-signature: sig, keyid="main", alg="rsa-v1_5-sha256"
accept: multipart/mixed,application/expo+json,application/json
```

- 인증 없음(공개). 둘러보기 사용자도 같다.

### 5.2 응답

`multipart/mixed`, 헤더 `expo-protocol-version: 1`, `expo-sfv-version: 0`,
`cache-control: private, max-age=0`. 파트는 셋 중 하나다.

**새 업데이트가 있을 때** — `manifest` 파트(`application/json`, `expo-signature` 헤더 포함):

```json
{
  "id": "0f3c…-uuid",
  "createdAt": "2026-11-24T10:00:00.000Z",
  "runtimeVersion": "0.3.18",
  "launchAsset": {
    "hash": "<SHA-256 base64url, 패딩 없음>",
    "key": "bundle-9a1b…",
    "contentType": "application/javascript",
    "url": "https://cdn.example/app/updates/0f3c…/android-9a1b….hbc"
  },
  "assets": [
    {"hash": "…", "key": "splash-3c2d…", "contentType": "video/mp4", "fileExtension": ".mp4",
     "url": "https://cdn.example/app/updates/assets/3c2d…"}
  ],
  "metadata": {},
  "extra": {"message": "셔틀 시간표 화면 수정", "critical": false}
}
```

**새 것이 없을 때** — `directive` 파트 `{"type": "noUpdateAvailable"}`.

**되돌릴 때** — `directive` 파트
`{"type": "rollBackToEmbedded", "parameters": {"commitTime": "<ISO 8601>"}}`.
앱은 다음 실행부터 설치 파일에 들어 있던 번들로 돌아간다.

- 같은 `runtimeVersion`·플랫폼·채널 안에서 **게시된 가장 최근 것** 하나만 준다.
  `expo-current-update-id`와 같으면 `noUpdateAvailable`.
- `assets[]`의 `key`·`hash`가 같은 파일은 앱이 다시 받지 않는다. 그림이 그대로면
  번들만 받으므로 보통 몇 백 KB다.
- `extra.critical`이 true면 앱이 받은 즉시 다시 시작한다(보안·데이터 손상 버그용).
  평소는 false. 앱은 `extra`의 모르는 필드를 무시한다.

### 5.3 서명(필수)

번들은 앱 전체 코드다. 가로채 바꾸면 앱을 통째로 바꿀 수 있으므로 **코드 서명을 반드시**
쓴다(Expo 「code signing」).

- 서버는 manifest 파트 본문을 RSA-SHA256(PKCS#1 v1.5)으로 서명해
  `expo-signature: sig="<base64>", keyid="main"` 헤더를 붙인다.
- 개인 키는 BFF 비밀 저장소에만 둔다. 앱에는 인증서(공개 키)만 들어간다
  (`updates.codeSigningCertificate`). 서명이 틀리면 앱은 그 업데이트를 버린다.
- 키 교체는 새 인증서를 넣은 스토어 배포가 필요하므로 키 분실·유출 절차를 미리 정해 두자.
- 번들·그림 파일은 `hash`(SHA-256)로 앱이 검증하므로 CDN에 그대로 둬도 된다.

### 5.4 runtimeVersion: OTA로 갈 수 있는 범위

OTA 번들은 **같은 네이티브 코드를 가진 설치본**에만 맞는다. 앱이 보내는
`expo-runtime-version`이 manifest의 `runtimeVersion`과 **정확히 같을 때만** 준다.

- 앱은 `runtimeVersion`을 앱 버전(`appVersion` 정책, 지금 `0.3.18`)으로 둔다.
  네이티브를 바꾸는 배포(Expo SDK 업그레이드, 네이티브 모듈 추가, 권한·아이콘·OS 시작 화면
  변경)는 앱 버전을 올려 스토어로 낸다. 그 버전용 OTA는 그때부터 따로 쌓인다.
- 서버는 runtimeVersion별로 업데이트 목록을 따로 들고, 옛 runtimeVersion도 지우지 않는다
  (스토어 업데이트를 안 한 사용자가 계속 받도록).

### 5.5 업로드(배포 파이프라인)

FE가 `npx expo export --platform android --platform ios`로 만든 `dist/`
(`metadata.json`, 번들 `.hbc`, `assets/`)를 올린다.

```
POST /admin/v1/updates        (운영자 인증)
multipart: dist.zip, runtime_version, channel, message
```

- 서버가 파일별 SHA-256을 계산해 CDN에 올리고 `metadata.json`으로 manifest를 만든다.
  업로드만 하고 **게시는 따로**(9장). 처음에는 `staging` 채널로 내부 기기에서 확인한 뒤
  같은 업데이트를 `production`으로 올린다(다시 빌드하지 않는다).
- GitHub Actions에서 부를 수 있게 운영 API 토큰을 하나 발급해 달라.

### 5.6 브랜드 에셋

스플래시 영상·포스터, 로고, 앱 안 아이콘은 번들에 들어 있는 그림이다. 바꾸려면 그림을
바꾼 OTA 업데이트를 낸다. **이전 요청의 `GET /app/v1/assets`와 `assets_version`은
필요 없어져 뺐다.**

## 6. 서비스 공지·FAQ·서비스 안내

```
GET /app/v1/announcements?cursor=…&limit=20
GET /app/v1/announcements/{id}
GET /app/v1/faqs
GET /app/v1/service-guide
```

서비스 공지 항목:

| 필드 | 형식 | 의미 |
|---|---|---|
| `id` | string | |
| `category` | `"update"` \| `"maintenance"` \| `"notice"` \| `"policy"` | 업데이트·점검·안내·약관 변경 |
| `title` | string | |
| `body` | string(Markdown) | 상세에서만. 그림은 4장과 같은 CDN |
| `pinned` | bool | 목록 맨 위 고정 |
| `published_at` | ISO 8601(+09:00) | |

- 목록은 고정 글 → 최신순, 커서 페이지네이션.
- FAQ: `[{id, question, answer(Markdown), order}]`. 서비스 안내: Markdown 한 문서.
- 모두 인증 없음.

## 7. 푸시 알림

앱은 알림을 받아 보여 주고, 누르면 약속된 화면으로 가고, 기기를 서버에 등록하는 데까지 만들어 두었다.
서버는 **기기 등록 API**와 **발송**을 맡아 달라. 알림 payload 형식은 [PUSH.md](PUSH.md) 3장을 그대로 쓴다.

### 7.1 기기 등록: `PUT /app/v1/push/devices`

앱은 토큰을 처음 받았을 때, 토큰이 바뀌었을 때, 로그인·로그아웃했을 때, 알림 설정을 바꿨을 때 이 요청을 보낸다.
같은 `token`이면 덮어쓴다(멱등).

```json
{
  "token": "<기기 토큰>",
  "platform": "android",
  "token_type": "fcm",
  "app_version": "0.3.19",
  "build": 3019,
  "preferences": { "push": true, "benefit": true, "marketing": false }
}
```

| 필드 | 설명 |
|---|---|
| `token` | 기기 토큰. 주소에 넣지 않는다(접근 로그에 남지 않게) |
| `platform` | `android` \| `ios` |
| `token_type` | 항상 `fcm`(FCM 등록 토큰). iOS도 앱이 Firebase Messaging으로 FCM 토큰을 받는다(2026-11-26 결정) |
| `app_version`, `build` | 빌드별 발송·장애 확인용 |
| `preferences.push` | false면 이 기기에 아무것도 보내지 않는다 |
| `preferences.benefit` | 혜택·이벤트 알림. **광고성 정보** |
| `preferences.marketing` | 마케팅 정보 수신. **광고성 정보** |

- **사용자 묶기**: `Authorization`(Keycloak 액세스 토큰)이 있으면 그 사용자와 기기를 묶는다. 없으면 묶음을 푼다
  (로그아웃 뒤 앱이 인증 없이 다시 보낸다). 비로그인(둘러보기) 기기도 등록된다.
- **응답**: 2xx면 된다. 본문은 쓰지 않는다.
- **탈퇴**: 계정 삭제 때 그 사용자에게 묶인 기기 등록을 지운다(개인정보처리방침 3장).
- **광고성 동의 이력**: `benefit`·`marketing`이 바뀐 시각을 기기(사용자)별로 남긴다. 정보통신망법 제50조에 따라
  2년마다 동의 여부를 다시 확인해야 하므로 동의 일자가 필요하다. 앱은 바꾸는 순간 「YYYY. M. D. … 수신 동의/거부 처리」를 화면에 알린다.

### 7.2 발송

- 공지 서비스가 이미 RabbitMQ topic exchange로 내는 이벤트(라우팅 키 `notice`, `notice.dormitory`, `shuttlebus`)를
  소비해 대상 기기를 고르고 FCM HTTP v1으로 보낸다(Android·iOS 공통).
- FCM이 `UNREGISTERED`·`INVALID_ARGUMENT`로 답한 토큰은 지운다.
- **광고성 알림**(`benefit`·`marketing`):
  - 해당 설정이 true인 기기에만 보낸다.
  - 제목 앞에 「(광고)」를 붙이고, 본문에 수신 거부 방법(마이 > 알림 설정)을 적는다.
  - 21시~다음 날 8시에는 보내지 않는다. 야간 발송은 별도 동의가 필요한데 앱에 그 설정이 없다.
- 학교 공지·셔틀 같은 정보성 알림은 `push`만 본다.
- Android 알림 채널은 `sandol_default`다. `android.notification.channel_id`를 생략하면 이 채널로 간다.

### 7.3 운영 화면

- 공지 이벤트 말고 운영자가 직접 보내는 알림(점검, 새 기능, 이벤트): 대상(전체·로그인 사용자·플랫폼·빌드 범위),
  광고성 여부(체크하면 7.2의 광고 규칙 적용), 예약 발송, 미리보기.
- 이동은 PUSH.md 3장 형식만 고를 수 있게 한다(공지 상세 또는 탭 5개). 임의 주소는 앱이 버린다.
- 발송 이력(누가, 언제, 몇 대에, 성공·실패 수).

## 8. 공통

- **그림**: 공개 https, 정해진 CDN 도메인만. 내용이 바뀌면 주소를 바꾼다
  (`...-v2.jpg`나 해시). 같은 주소에 덮어쓰면 기기 캐시 때문에 옛 그림이 남는다.

  | 대상 | 비율 | 업로드 크기 | 형식 / 용량 |
  |---|---|---|---|
  | 홈 배너(image) | 345:138 | 1035×414(3배) | JPG·WebP, 300KB 이하 |
  | 배너 아이콘, 앱 아이콘 교체 | 1:1 | 단색 SVG | 10KB 이하, 스크립트·외부 참조 없음 |

- **캐시**: `ETag`·`304` 지원, `Cache-Control: max-age=300`. 앱은 5초 넘으면 저장본을 쓴다.
- **오류**: 실패는 HTTP 상태 코드로. 앱은 2xx가 아니면 모두 「서버 실패」로 본다.

## 9. 운영 화면(어드민)

- 홈 배너: 등록·수정·삭제, 끌어서 순서 바꾸기, 게시 기간, 플랫폼, 빌드 범위, 즉시 내리기.
- 서비스 공지·FAQ·서비스 안내: Markdown 편집과 미리보기, 고정, 예약 게시.
- **OTA 업데이트**: runtimeVersion·플랫폼·채널별 목록, staging → production 게시,
  게시 중지, 이전 업데이트 다시 게시(되돌리기), 설치 파일 번들로 되돌리기(`rollBackToEmbedded`),
  `critical` 표시. 누가 언제 게시했는지 남긴다.
- 최소 지원 빌드(`min_supported_build`) 설정.
- 점검 안내: 문구·기간·막기 여부.
- 휴대폰 크기 미리보기(412폭, 글자 2배 포함). `link`는 4.3 규칙으로 검사하고 앱 경로는 목록에서 고른다.
- 권한: 학생회 등 외부 담당자는 배너 **초안**만, 게시는 운영자 승인 후. 변경 이력을 남긴다.

## 10. 나중에(이번 요청 아님)

- 노출·클릭 집계(`POST /app/v1/contents/events`). 개인 식별 값은 싣지 않는다.
- 학과·학년별 맞춤 배너: 로그인 정보가 필요해 보류.
- OTA 단계적 배포(일부 사용자에게만 먼저): 기기 구분 값이 필요해 보류. 지금은 staging 채널로 대신한다.
- OTA 받기·적용 성공률 집계.

## 11. 앱 쪽 준비 상태

| 항목 | 상태 |
|---|---|
| RN(Expo SDK 58) 이식 | 완료(`handol-rn/`) |
| `expo-updates` 설치·서명 인증서·채널 설정 | 서버 주소 확정 후(앱 설정 몇 줄) |
| 「스토어에서 업데이트」 화면(`min_supported_build`) | API 확정 후 |
| 배너 모델·링크 규칙·여러 장 넘기기·서버 그림 대체 | 완료(테스트 있음) |
| 배너 API 호출, 저장본, `ends_at` 거르기 | 완료(2026-11-27). `image_url`·본문 그림은 https 또는 BFF `/app/v1/assets/...` 경로. 글자 배너 아이콘은 `icon_url` 대신 링크 화면의 앱 아이콘 |
| 점검 안내 화면 | API 확정 후 |
| 푸시 수신·표시, 누르면 화면 이동, 알림 권한, 기기 등록 호출(7.1), 광고성 동의 일자 안내 | 완료. Firebase 설정 파일을 넣고 빌드하면 켜진다 |
| 서비스 공지 목록·상세, FAQ, 서비스 안내 화면 | 완료(2026-11-27). 마이 > 공지사항·자주 묻는 질문·서비스 안내. 목록은 첫 50개 |

## 12. 정해 주셔야 할 것

1. 서버 주소와 경로(`/app/v1/...` 제안).
2. OTA를 BFF가 직접 할지, Expo 호스팅(EAS Update, 유료 구간 있음)을 쓸지. 이 문서는 직접 구현을
   전제로 한다. EAS를 쓰면 5장 서버 구현은 빠지고 `min_supported_build`만 남는다.
3. 코드 서명 키를 누가 만들고 어디에 보관할지.
4. 그림·번들 CDN 도메인.
5. 어드민을 누가 쓰는지(운영자만 / 학생회 포함)와 승인 절차. OTA 게시는 운영자만 제안.
6. 첫 광고의 링크(학생회 인스타 등).
7. 푸시 발송 주체(BFF가 RabbitMQ를 직접 소비할지, 별도 알림 서버를 둘지)와 Firebase 프로젝트를 만들 팀 계정.
8. ~~iOS 푸시 방식~~ → FCM 통일로 결정, APNs 키(.p8)도 Firebase 콘솔에 등록함(2026-11-26).
