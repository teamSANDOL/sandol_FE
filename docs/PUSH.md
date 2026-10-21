# 서버 푸시 알림 (앱 기반)

앱은 FCM 메시지를 받아 보여 주고, 탭하면 약속된 화면으로 이동하는 데까지만 준비돼 있다.
알림 기능(공지 키워드·카테고리 등)과 서버는 아직 없다. 코드는 `lib/core/push/push_service.dart`.

- Firebase 설정 파일이 없으면 초기화가 실패하고 **푸시만 꺼진 채** 앱은 정상 실행된다.
- 알림 권한은 아직 요청하지 않는다. 기능이 생기면 `PushService.requestPermission()` 을 호출한다.
  (Android 13+ 는 권한이 없으면 알림이 표시되지 않는다.)

## 1. Firebase 프로젝트와 설정 파일

1. 팀 계정으로 Firebase 프로젝트를 만들고 Android 앱(`kr.sandori.app`), iOS 앱(번들 ID는 Xcode 의 값)을 등록한다.
2. 받은 파일을 아래에 둔다. 둘 다 `.gitignore` 대상이다(비밀은 아니지만 환경별로 달라서).
   - Android: `android/app/google-services.json` — 파일이 있을 때만 google-services Gradle 플러그인이 적용된다.
   - iOS: `ios/Runner/GoogleService-Info.plist` — Xcode 에서 Runner 타깃에 추가(Copy items).
3. 배포 빌드 환경(CI·빌드 PC)에도 같은 파일을 넣어야 푸시가 켜진다.

## 2. 플랫폼 준비

- **Android**: 추가 작업 없음. 알림 채널 `sandol_default`(산돌이 알림)를 앱이 만들고, 백그라운드 알림도 이 채널을 쓴다(`AndroidManifest.xml` meta-data).
- **iOS** (Windows 에서 빌드 검증 안 됨)
  - Apple Developer → Keys 에서 APNs 키(.p8)를 만들어 Firebase 콘솔 → 프로젝트 설정 → 클라우드 메시징에 업로드.
  - Xcode → Runner → Signing & Capabilities 에 **Push Notifications**, **Background Modes → Remote notifications** 추가.
  - 포그라운드 알림이 안 뜨면 `AppDelegate.swift` 에 `UNUserNotificationCenter.current().delegate = self` 추가를 검토.

## 3. payload 형식

알림 내용은 `notification`(title/body), 이동 정보는 `data` 에 넣는다. `data` 값은 모두 문자열이다.
약속에 맞지 않는 `data` 는 무시한다(임의 딥링크 차단).

| 형태 | 키 | 이동 |
|---|---|---|
| 공지 상세 | `type`=`notice`, `id`, `url`, `title`, `author`(선택), `created_at`(선택) | 공지 상세(WebView). `url` 은 `https` + `tukorea.ac.kr` 또는 하위 도메인만 |
| 탭 | `route` = `/home` `/meal` `/bus` `/notice` `/map` 중 하나 | 해당 탭 |

```json
{
  "message": {
    "token": "<기기 토큰>",
    "notification": { "title": "새 공지", "body": "2026학년도 수강신청 안내" },
    "data": {
      "type": "notice",
      "id": "1234",
      "url": "https://www.tukorea.ac.kr/...",
      "title": "2026학년도 수강신청 안내",
      "author": "학사팀",
      "created_at": "2026-10-21"
    }
  }
}
```

종료 상태에서 알림으로 열면 스플래시 선로딩 뒤 그 화면으로 간다. 로그인 화면으로 가야 하는 경우(비로그인·둘러보기 만료)는 이동을 버린다.

## 4. 서버가 할 일

- **토큰 등록 API**: 앱은 토큰 발급·갱신 때와 로그인 상태가 바뀔 때 `PushTokenRegistrar.register(token, loggedIn:)` 을 부른다.
  지금은 `NoopPushTokenRegistrar` 가 아무것도 보내지 않는다. API 가 생기면 이 구현을 바꾸고 `pushServiceProvider` 에 넣는다.
  로그인 사용자는 `Authorization` + `X-User-ID` 규약으로 사용자와 토큰을 묶는다.
- **발송**: 공지 서비스는 이미 RabbitMQ topic exchange 로 이벤트를 발행한다(라우팅 키 `notice`, `notice.dormitory`, `shuttlebus`).
  알림 서버가 이를 소비해 대상 토큰을 고르고 FCM HTTP v1 으로 위 형식을 보낸다. FCM 이 무효(UNREGISTERED)라고 답한 토큰은 지운다.
- 앱은 FCM 등록 토큰(`getToken`/`onTokenRefresh`)을 쓴다. firebase_messaging 17 은 이를 deprecated 로 표시하고
  FID(`register`/`onRegistered`) 방식을 권하므로, 서버 발송 방식을 정할 때 함께 결정한다.

## 5. 개인정보·스토어

푸시를 켜는 배포 전에:
- 개인정보처리방침(`docs/privacy-policy.html`)에 수집 항목 "기기 푸시 토큰"(목적: 알림 발송, 보관: 탈퇴·토큰 만료 시 삭제) 추가.
- Play Console Data safety(`docs/PLAY_RELEASE.md` 표)에 "기기 또는 기타 ID → 수집, 앱 기능(알림)" 반영.
