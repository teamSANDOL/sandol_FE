# 한돌이 React Native 이식 가이드

Flutter 앱(저장소 루트 `lib/`)을 Expo(SDK 58, RN 0.88, expo-router)로 옮긴 프로젝트다. **목표는 현재 Flutter 앱의 디자인을 픽셀 단위로 그대로 재현하는 것**이다.

## 구조
```
handol-rn/
  src/app/                 expo-router 라우트(얇은 re-export 만. 화면 로직 금지)
  src/design-system/       토큰 · 타이포 · 에셋 · 공용 컴포넌트 (import from '@/design-system')
  src/core/                env, api/client, auth, query, location, utils
  src/features/<feature>/  screens/ components/ api.ts(데이터) hooks.ts model.ts __tests__/
  assets/                  Flutter assets 복사본 (design_system, fonts, icon, img, lottie)
```

## 디자인 시스템 규칙 (필수)
- 색 · 간격 · 반지름 · 그림자 · 그라데이션은 `colors / spacing / radius / metrics / shadows / gradients` 토큰만 쓴다. 16진수 색 리터럴을 화면 코드에 쓰지 않는다. 토큰에 없는 시안 색이 꼭 필요하면 기능 폴더의 `<feature>/theme.ts` 에 이름 붙여 한 곳에 모은다.
- 글자는 `<HText variant="caption|body|headline|title|button" weight="bold" tone="muted|accent|onPrimary|inactive|secondary|danger" />`. 옛 화면 스타일(AppTextStyles)은 `legacy="title01"` 등. fontSize · fontFamily 를 직접 쓰지 않는다. (Flutter `caption.strong.accent` = `variant="caption" weight="bold" tone="accent"`)
- Flutter 위젯 대응: HandolCard, HandolButton, HandolChip, HandolSection, HandolIconButton, HandolIconLabel/HandolNote, HandolCheckbox, Chevron, AppTopBar, GradientScrollView/GradientBackground(HandolScrollGradient), LoadingIndicator(Lottie), ErrorRetryView, RemoteImage, showToast/showComingSoon, HPressable(InkWell).
- 아이콘: `<Icon name="busSwap" />` (src/design-system/assets.ts 의 icons). 비트맵은 `images.xxx` + expo-image `<Image>`.
- 한글 줄바꿈: Flutter 에서 `.keepAll` 을 쓴 곳은 `<HText keepAll>` 또는 `keepAll()` (src/core/utils/keepAll.ts).
- dp 단위는 Flutter logical px 와 같다. Flutter 코드의 숫자(패딩, 높이, 폭)를 그대로 쓴다.
- 여러 기능에서 다시 쓸 만한 컴포넌트는 기능 폴더 안 `components/` 에 만들고 props 로 일반화한다. src/design-system 의 기존 파일은 수정하지 않는다(필요하면 보고).

## 데이터
- HTTP: `api.get<T>(path, { query })` (src/core/api/client.ts). 인증 · 대체 서버 재시도 · 타임아웃 포함. Flutter Retrofit 경로를 그대로 옮긴다(baseUrl 은 https://sandori.kr).
- 서버 상태: TanStack Query (`useQuery`). queryKey 는 `['<feature>', ...]`.
- 응답 → 도메인 모델 매핑은 `api.ts` 안에서. DTO 를 화면에 직접 쓰지 않는다.
- KST 기준 시각: `koreaNow()`, `kstParts()` (src/core/utils/koreaTime.ts). 날짜 포맷: dateFormatter.ts.
- 위치: `useUserLocation()`, `distanceMeters()` (src/core/location/userLocation.ts).
- 로컬 저장(북마크 · 읽음 · 설정): @react-native-async-storage/async-storage.
- 인증: `useAuth()` (src/core/auth/AuthProvider.tsx) → status, session, login({useKakao, signUp, rememberMe}), logout, deleteAccount, continueAsGuest. `displayId(session)`.

## 라우트
/ (스플래시) · /login · /(tabs)/home · /home/organization · /home/organization/search?query= · /meal · /bus · /notice · /notice/detail · /map · /user · /user/policy/[doc] · /user/withdraw · /user/withdraw/confirm
탭 이동: `router.navigate('/bus')`. 탭 바와 상단 바는 이미 있다(각 화면이 AppTopBar 를 직접 그린다 — Flutter 와 같다).

## 기능 간 계약 (이름 · props 변경 금지)
- bus: `components/BusTimeCard.tsx` → `BusTimeCard({ onPress })`
- school_meal: `components/HomeMealSection.tsx` → `HomeMealSection({ onPress })` (로딩 · 오류 · 빈 상태 포함)
- empty_class: `components/EmptyClassTimelineCard.tsx` → `EmptyClassTimelineCard({ maxItems, onBuildingPress })`, `components/BuildingSortButton.tsx` → `BuildingSortButton()`, `focus.ts` (이미 구현됨)
- organization: `components/OrganizationQuickCard.tsx` → `OrganizationQuickCard({ onOpenAll })`

## 검증
- `npx tsc --noEmit` 오류 0, `npx jest` 통과. 순수 로직(시간표 계산, 매핑, 정렬 등)은 `__tests__` 에 단위 테스트.

## 실행 · 빌드 (Windows)
워크트리 경로에 한글이 있고 RN 네이티브 빌드 경로가 길어 그대로는 Gradle 이 실패한다. ASCII 짧은 경로 미러에서 빌드한다.
1. 미러 동기화: `robocopy <repo>\handol-rn C:\h\rn /MIR /XD node_modules android ios .expo`, 서명 키는 `C:\h\android\key.properties`(+jks), `.env` 는 `C:\h\.env`.
2. 처음 한 번: `cd C:\h\rn && npm ci && npx expo prebuild -p android --no-install`
3. `C:\h\rn\android\local.properties`: `sdk.dir=...Android/Sdk`, `cmake.dir=C:/h/tools/cmake-3.31.6-windows-x86_64` (SDK 기본 CMake 3.22 의 ninja 는 260자 넘는 경로를 못 만든다. Kitware CMake 3.31 zip + ninja 1.12 를 같은 bin 에 둔다).
4. 개발: `./gradlew assembleDebug -PreactNativeArchitectures=arm64-v8a` → `adb install -r`, `npx expo start --dev-client` + `adb reverse tcp:8081 tcp:8081`. 소스를 고치면 1번 동기화만 다시 하면 Fast Refresh 된다.
5. 단독 실행 APK: `./gradlew assembleRelease -PreactNativeArchitectures=arm64-v8a` → `android/app/build/outputs/apk/release/app-release.apk`.
- 패키지명은 Flutter 앱과 같은 `app.handol.student`(네이버 지도 키가 패키지에 묶여 있다). `plugins/withSharedSigning.js` 가 저장소 `android/key.properties` 키로 debug·release 를 서명하므로 기존 설치본 위에 데이터 유지한 채 덮어쓸 수 있다.

## 알려진 차이 · 구현 메모
- 글자 폭: Flutter 는 keepAll 의 WORD JOINER 에도 자간을 적용하고 마지막 글자 뒤에도 자간을 붙인다. HText 가 두 가지를 보정한다(keepAllSpacing · trailingSpacing). 줄바꿈 경계까지 Flutter 와 같게 맞춘 것을 에뮬레이터에서 픽셀 비교로 확인했다.
- 바텀시트: Flutter showModalBottomSheet 는 탭 바를 덮지 않는다. 탭 스택마다 BottomSheetHost 를 두고 HandolBottomSheet 를 쓴다(RN Modal 금지. 대화상자는 Flutter 도 전체를 덮으므로 Modal 그대로).
- Material 아이콘: design-system/materialIcons.ts 의 원본 path 만 쓴다(직접 그리지 않는다).
- 네이버 지도 마커는 한번 올리면 내리지 않고 isHidden 으로 감춘다. 오버레이를 제거하면 라이브러리가 IndexOutOfBounds 로 앱을 죽인다.
- 지도 타일: Flutter 앱과 마찬가지로 현재 키로는 회색 격자(마커 · 시트는 정상).
- 로그인: Keycloak PKCE(expo-auth-session). 로그인 페이지 열림 · 취소 처리까지 확인. 실제 계정 로그인 완료 · 탈퇴 서버 호출은 테스트 계정이 없어 미확인.
- 푸시 알림(Firebase)은 옮기지 않았다(Flutter 도 google-services.json 이 없으면 비활성).
