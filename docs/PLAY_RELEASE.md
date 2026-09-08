# Google Play 출시 체크리스트

2026-09-08 감사에서 나온 업로드 차단 항목 3개의 처리 상태와, 코드 밖에서
사람이 직접 해야 하는 작업을 정리한다.

## 1. 패키지명 — 완료 (코드)

- `applicationId` / `namespace` = `kr.sandori.handori`
- `MainActivity.kt` → `android/app/src/main/kotlin/kr/sandori/handori/`
- 딥링크 스킴 `kr.sandori.handori://oauthredirect` 는 패키지명과 무관하므로 Keycloak 설정 변경 불필요.

**직접 해야 할 일**
- [x] NCP 콘솔 → Maps → Application → Android 앱 패키지명을 `kr.sandori.handori` 로 교체 (2026-09-08 완료)(구 `com.example.handori` 삭제). 안 하면 릴리즈 빌드에서 지도가 빈 화면.
- [ ] 이미 설치된 테스트 기기의 구 패키지 앱은 별개 앱으로 남으므로 삭제.

## 2. 릴리즈 서명 — 완료 (코드) + 백업 필요

- `android/upload-keystore.jks` (alias `upload`, PKCS12, 유효기간 2054-01-24까지)
- `android/key.properties` 에 비밀번호. 둘 다 gitignore 대상.
- `build.gradle.kts` 는 `key.properties` 가 없으면 릴리즈 빌드를 실패시킨다(debug 서명으로 조용히 대체하지 않음).
- 업로드 키 SHA-256: `61:63:EB:88:C6:D0:41:AA:AF:40:D0:56:C2:51:86:6F:0C:5F:75:E3:23:0D:43:6F:88:61:4B:38:31:A2:43:AA`

**직접 해야 할 일**
- [ ] `upload-keystore.jks` + `key.properties` 를 팀 비밀 저장소(1Password, Bitwarden 등)에 백업. 분실 시 앱 업데이트 불가.
- [ ] Play Console 첫 업로드 시 Play App Signing 에 등록(자동). 이 키는 "업로드 키"이며 배포 서명키는 Google 이 관리한다.

## 3. 개인정보처리방침 · 계정 삭제 · Data safety — 코드 완료, 호스팅 필요

앱은 다음 URL 을 연다 (`lib/core/constants/api_constants.dart`):

| 용도 | URL | 원본 파일 |
|---|---|---|
| 개인정보처리방침 | https://sandori.kr/privacy | `docs/privacy-policy.html` |
| 계정 삭제 요청 | https://sandori.kr/account-deletion | `docs/account-deletion.html` |

앱 내 진입점: 마이페이지 → "개인정보처리방침", 회원가입 → "개인정보 수집 동의(필수)" 제목 탭.
앱 내 계정 삭제: 마이페이지 → 회원 탈퇴 (Keycloak Account API DELETE, 기존 구현).

**직접 해야 할 일**
- [ ] 두 HTML 의 `[담당자 이메일]` 을 실제 팀 연락처로 교체(3곳).
- [ ] 백엔드 팀에 확인: 빈 강의실 API 로 보내는 위도·경도를 서버가 저장하지 않는지. 방침 2·3조가 "저장하지 않음"으로 쓰여 있으므로 사실과 다르면 문구 수정.
- [ ] 회원가입 필드 확인: 방침 1조는 아이디·이름·이메일·생년월일을 적었다. Keycloak 등록 폼과 다르면 맞출 것.
- [ ] sandori.kr 게이트웨이에 정적 파일 두 개 서빙 (nginx 예: `location = /privacy { alias /srv/docs/privacy-policy.html; }`).
  대안: 이 저장소 GitHub Pages(Settings → Pages → main, `/docs`)를 켜고 `ApiConstants` 의 두 URL 을
  `https://teamsandol.github.io/sandol_FE/privacy-policy.html` 형태로 바꾼다.
- [ ] Play Console → 앱 콘텐츠 → 개인정보처리방침 URL 입력.
- [ ] Play Console → 앱 콘텐츠 → 데이터 보안(Data safety) 작성. 아래 표 그대로.
- [ ] Play Console → 앱 콘텐츠 → 계정 삭제 → 웹 URL 에 계정 삭제 페이지 입력, "앱에서 삭제 가능" 체크.

### Data safety 답변

| 질문 | 답 |
|---|---|
| 데이터 수집/공유 여부 | 수집함, 공유 안 함 |
| 전송 중 암호화 | 예 (HTTPS) |
| 삭제 요청 방법 제공 | 예 (앱 내 + 웹) |
| 위치 → 정확한 위치 | 수집, 앱 기능(거리순 정렬)용, 선택 사항, 임시 처리(저장 안 함) |
| 개인 정보 → 이름 | 수집, 계정 관리, 필수(로그인 시) |
| 개인 정보 → 이메일 주소 | 수집, 계정 관리, 필수(로그인 시) |
| 개인 정보 → 사용자 ID | 수집, 계정 관리, 필수(로그인 시) |
| 개인 정보 → 기타(생년월일) | 수집, 계정 관리, 필수(로그인 시) |
| 앱 활동, 기기 ID, 광고, 분석 | 수집 안 함 |
| 앱 정보 및 성능 → 진단 | 수집 안 함 (크래시 리포팅 도입 시 "충돌 로그" 추가) |

## 4. 보안·안정성 (2026-09-08 감사 HIGH 항목) — 코드 완료

- `.env` 에서 `GYEONGGI_BUS_API_KEY` 제거(앱이 사용하지 않음). `dotenv.load(isOptional: true)` 로 파일이 없어도 앱은 뜬다.
  단, `pubspec.yaml` 의 asset 등록 때문에 파일 자체가 없으면 `flutter build` 는 여전히 실패한다 → 클린 체크아웃에서는 `cp .env.example .env` 먼저.
- `TokenStorage.read()` 가 보안 저장소 예외를 잡아 세션을 초기화하고, 스플래시는 복원 실패 시 로그인 화면으로 간다.
- `lib/core/error/app_error_handler.dart` 가 `FlutterError.onError` + `PlatformDispatcher.onError` 를 설치한다. 현재는 로그만 남기는 리포터.
- 공지 DTO 의 `html` 을 nullable 로 바꾸고 도메인에서 제거했다(백엔드가 필드를 빼도 파싱 안 깨짐).

**직접 해야 할 일**
- [ ] 공공데이터포털(data.go.kr) 마이페이지 → 활용신청 현황 → GBIS 인증키 **재발급**. 구 키는 공개 GitHub 히스토리(커밋 `a37b9d8`)에 남아 있다. 새 키는 앱에 넣지 말 것(앱이 쓰지 않음).
- [ ] 크래시 리포팅 백엔드 연결: Firebase Crashlytics 또는 Sentry 프로젝트를 만들고 `CrashReporter` 를 구현해 `installGlobalErrorHandlers(reporter: …)` 에 넘긴다. Firebase 는 `google-services.json` 이 필요하므로 팀 Firebase 계정으로 생성.
- [ ] 백엔드 팀에 요청: `GET /notice-notification/notice` 응답에서 `html`·`content` 제외(또는 `?fields=` 지원). 현재 항목당 100~280KB 라 gzip 후에도 페이지당 약 275KB, 압축 해제·JSON 파싱은 2.4MB.

## 5. 체감 결함 (감사 MEDIUM 8건) — 코드 완료

- 셔틀 시계(`ShuttleClock`)가 분 단위로 자동 갱신 + 백그라운드 복귀 시 셔틀·강의실 구간 재동기화.
- 홈 빈 강의실 카드: API 와 GPS 를 병렬 시작. 당겨서 새로고침은 위치가 없고 권한이 이미 허용된 경우에만 GPS 재시도.
- 홈·학식 탭이 같은 `mealListNotifierProvider()` 인스턴스를 공유(중복 요청 제거).
- 스플래시 이미지 축소(배경 1242px JPEG 114KB, 캐릭터 900px) + 미사용 이미지 9개 삭제.
- 공지 WebView 콜백 `mounted` 확인.
- 지도 마커 아이콘 캐시 LRU 64개 상한 + dispose 시 정리. (flutter_naver_map 이 임시 디렉터리에 쓰는 PNG 는 OS 가 정리)
- 셔틀 계산: 구간 종료 시각 미포함, 아직 시작 안 한 구간은 시작 시각 대기로 표시. 셔틀·식단·강의실 "지금"을 `KoreaTime.now()`(KST) 로 통일. 테스트 `test/features/bus/next_shuttle_calculator_test.dart`.
- 빈 강의실·조직도 오류 화면을 사용자 문구 + 재시도로 교체. 계정 삭제 요청 10초 타임아웃. 게스트에게는 회원 탈퇴 숨김.

**남은 데이터 문제 (코드 아님)**
- [x] 셔틀 시간표 확인 완료 (2026-09-08 사용자 확인: 노선1·2 모두 현행과 일치)
- [x] 공휴일 처리 완료 (2026-09-08). `lib/features/bus/data/data_source/korean_public_holidays.dart` 에 2026·2027 공휴일(대체공휴일 포함) 하드코딩, 셔틀은 공휴일에 미운행으로 판정.
  - [ ] **매년 6월 말 월력요항 발표 후 다음 해 목록 추가.** 목록 밖 연도는 요일만으로 판정(공휴일을 평일 취급)하므로 빠뜨리면 공휴일에 "운행 중"으로 보인다.
  - [ ] 2027 목록은 대체공휴일 규정으로 산출한 값. 2027 월력요항 확정본과 대조 필요. 임시공휴일은 지정될 때 수동 추가.

## 6. 코드 리뷰 반영 (2026-09-08)

7개 관점 리뷰에서 나온 결함·퇴행을 수정했다.
- 릴리즈 키 검사가 구성 단계에서 실행돼 디버그 빌드까지 막던 문제 → 릴리즈 태스크가 실행 그래프에 있을 때만 실패. (키 없이 `flutter build apk --debug` 성공, `appbundle --release` 실패 확인)
- 토큰 저장소 읽기 실패 시 토큰 7개를 지우던 것 → 지우지 않고 이번 실행만 비로그인. `readAll()` 한 번으로 읽고, 저장·삭제는 병렬.
- 빈 `.env` 로 시작하면 크래시 → 로드 실패 시 빈 환경으로 초기화.
- 릴리즈에서 전역 예외 로그가 logger 필터에 걸려 사라지던 것 → ProductionFilter.
- 버스 상세 시간표의 "다음 출발" 강조가 위 카드와 다른 항목을 가리키던 것 → 같은 규칙으로 통일. "수시운행" 표기 통일.
- 셔틀 시계: 구독자 없으면 정지, 분 경계에 맞춘 단발 타이머.
- 홈 새로고침: 강의실 API 를 먼저 부르고, 권한 허용 사용자는 위치를 새로 잡되 인디케이터는 GPS 를 기다리지 않음.
- 공지 DTO 에서 `html` 필드 제거. 오류 화면 공용 위젯(`shared/widget/error_retry_view.dart`), 링크 헬퍼 통합.

**리뷰가 찾았지만 이번 세션 이전부터 있던 것 (미수정)**
- [x] 로그아웃 중 진행 중이던 토큰 리프레시가 끝나면 세션이 되살아나는 경쟁 조건 → 세대 번호로 해결 (2026-09-08). 저장소(`AuthRepositoryImpl._generation`)와 화면 상태(`AuthNotifier._epoch`) 양쪽에서 로그인·로그아웃·탈퇴마다 세대를 올리고, 기다리던 리프레시는 세대가 바뀌었으면 결과를 버리고 서버가 새로 준 리프레시 토큰을 폐기한다. Keycloak 호출용 Dio 도 하나로 통합(10초). 테스트 2개 추가.
- [x] 로그아웃 순서 수정 (2026-09-08): `/logout` 을 먼저 호출하고, 실패했을 때만 `/revoke` 로 대체. 성공 시 서버 호출 1회. 테스트 추가.
- [ ] 학식·공지 화면의 오류 뷰도 `ErrorRetryView` 로 교체하면 문구·버튼이 통일된다.

## 7. 2차 코드 리뷰 반영 (2026-09-08)

7개 관점 재검토에서 나온 결함·퇴행을 추가로 수정했다.
- 로그아웃 서버 호출 중에 시작된 리프레시가 세대 검사를 통과하던 빈틈 → 저장소를 비운 뒤 세대를 한 번 더 올림. 늦게 온 리프레시는 null 대신 "현재 저장소 상태"를 돌려주므로 화면 쪽 카운터(`_epoch`) 제거. 세션 스트림 리스너는 로그인 진행 중(AsyncLoading)에는 상태를 덮지 않음.
- 토큰 만료 시각을 시간대 없이 저장 → UTC(Z) 로 저장. 기기 시간대가 바뀌어도 만료 판정이 어긋나지 않음.
- 리프레시 토큰 로컬 만료 판정에 시계 오차 허용치 1시간. 그 안이면 서버에 물어봄.
- `invalid_grant` 외 영구 OAuth 오류(`invalid_scope`, `unauthorized_client`, `invalid_client`, `not_allowed`, `access_denied`)도 세션 정리 → 15초마다 서버를 두드리는 좀비 세션 방지.
- 탈퇴는 백오프를 무시하고 갱신을 시도하며, 유효 토큰이 없으면 401 대신 명확한 안내로 실패.
- 보안 저장소 readAll 실패 시 키별 읽기로 재시도하고, 그래도 실패하면 결과를 캐시하지 않아 다음 읽기·복귀에서 되살아남. 복귀 시 갱신은 비로그인 상태에서도 저장소를 다시 읽음.
- 버스 상세 시간표: 구간 종료 정각부터 "지남" 처리, 아직 시작 전인 다음 구간은 '다음' 표시(진행 중 구간과 구분).
- `NextShuttle`·`ShuttleTime` 값 동등성 → 분마다 결과가 같으면 카드가 다시 그려지지 않음.
- 셔틀 시계 타이머는 구독 위젯이 있을 때만 돌고, 앱이 paused 면 멈춤.
- 스플래시 이미지를 화면 크기로 디코드하고 dispose 시 이미지 캐시 비움.
- 홈 새로고침의 위치 재시도: 위치 서비스가 켜져 있고 영구 거부가 아니면 다시 잡음(첫 실행 때 GPS 가 꺼져 있어 못 물은 사용자 복구).
- `key.properties` 가 있어도 항목이 빠졌으면 경고만 하고 디버그 빌드는 통과, 릴리즈만 실패.
- 공휴일 목록 만료를 런타임 로그 대신 테스트로 검출(지금 + 180일이 목록 안인지). 지도 마커 캐시 LRU 제거. 학식·공지 오류 화면도 공용 `ErrorRetryView` 로 통일. `DateFormatter.isoDate` 공용화.

**미반영(설계 판단)**
- KST 시각을 `isUtc` DateTime 으로 나르는 대신 전용 값 타입을 두자는 제안 — 범위가 커서 보류. 현재 모든 소비처가 시·분·요일만 읽는 것은 확인됨.
- 토큰 7개 키를 JSON 한 키로 합치기 — 기존 사용자 마이그레이션이 필요해 보류.
- 백오프 창에서 요청을 익명으로 보내는 정책(만료 토큰을 붙이지 않음)은 이전 세션의 의도적 선택이라 유지.
- iOS 번들 ID 는 아직 `com.example.handori`. App Store 준비 시 변경 + NCP iOS 항목 재등록 필요.

## 8. 출시 전 마지막 확인

- [ ] `flutter build appbundle --release` 성공 + `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab` 로 서명자가 `CN=Sandori Handori` 인지 확인.
- [ ] 개인 개발자 계정이면 비공개 테스트 12명 × 14일 선행.
- [ ] 릴리즈 빌드를 실기기에 설치해 지도 타일(NCP 재등록 확인)과 카카오·아이디 로그인 왕복 확인.
