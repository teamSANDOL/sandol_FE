const fs = require('fs');
const path = require('path');
const { withGradleProperties } = require('expo/config-plugins');

/**
 * 저장소 루트의 .env(Flutter 앱과 공유, gitignore)를 읽는다. 없으면 빈 값이라
 * 지도만 비활성이고 앱은 뜬다. 값은 로그에 남기지 않는다.
 */
function readEnv() {
  const file = path.resolve(__dirname, '..', '.env');
  if (!fs.existsSync(file)) return {};
  return Object.fromEntries(
    fs
      .readFileSync(file, 'utf8')
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#') && line.includes('='))
      .map((line) => {
        const i = line.indexOf('=');
        return [line.slice(0, i).trim(), line.slice(i + 1).trim()];
      }),
  );
}

const env = readEnv();
/** Firebase 설정 파일이 있을 때만 Firebase(분석·FCM)를 붙인다. 없으면 분석·푸시만 꺼진 채 빌드된다(docs/PUSH.md). */
const exists = (f) => fs.existsSync(path.resolve(__dirname, f));
const hasAndroidFirebase = exists('google-services.json');
const hasIosFirebase = exists('GoogleService-Info.plist');
const fonts = ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold', 'Black']
  .map((w) => `./assets/fonts/Pretendard-${w}.otf`)
  .concat('./assets/fonts/Krub-Bold.ttf');

module.exports = {
  expo: {
    name: '한돌이',
    slug: 'handol',
    // Keycloak 로그인 딥링크(kr.sandori.handori://oauthredirect)와 같은 스킴
    scheme: 'kr.sandori.handori',
    version: '0.3.23',
    // OTA 업데이트(자체 서버, docs/OTA_UPDATE_SERVER.md). 같은 version 으로 나간 스토어 빌드끼리만 JS 번들을 나눠 받는다.
    // 네이티브(패키지·권한·플러그인)를 바꾸면 version 을 올려 스토어에 새로 올린다.
    runtimeVersion: { policy: 'appVersion' },
    updates: {
      // 이미 배포된 앱은 이 주소를 OTA 로 바꿀 수 없다. 서버를 옮겨도 이 도메인은 유지한다.
      url: 'https://update.handol.app/api/manifest',
      // 실행은 기다리지 않는다. 받은 업데이트는 다음 실행에 적용된다.
      checkAutomatically: 'ON_LOAD',
      fallbackToCacheTimeout: 0,
      // 서버가 털려도 우리 개인키(keys/, 저장소 밖 보관)로 서명한 번들만 받는다.
      codeSigningCertificate: './certs/certificate.pem',
      codeSigningMetadata: { keyid: 'main', alg: 'rsa-v1_5-sha256' },
    },
    orientation: 'portrait',
    icon: './assets/icon/app_icon.png',
    // 화면 색이 토큰으로 고정돼 있어 다크 모드를 지원하지 않는다(Flutter 와 동일).
    userInterfaceStyle: 'light',
    backgroundColor: '#FDFDFD',
    android: {
      // 네이버 지도 키가 패키지명에 묶여 있어 Flutter 앱과 같은 ID 를 쓴다.
      package: 'app.handol.student',
      versionCode: 3023,
      ...(hasAndroidFirebase && { googleServicesFile: './google-services.json' }),
      // 개발 메뉴용 오버레이, 쓰지 않는 저장소, 광고 ID(광고 SDK 없음)는 배포본에서 뺀다.
      blockedPermissions: [
        'android.permission.SYSTEM_ALERT_WINDOW',
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.WRITE_EXTERNAL_STORAGE',
        'com.google.android.gms.permission.AD_ID',
        // Firebase Analytics(measurement)가 넣는 광고 측정 권한
        'android.permission.ACCESS_ADSERVICES_ATTRIBUTION',
        'android.permission.ACCESS_ADSERVICES_AD_ID',
      ],
      adaptiveIcon: {
        // 전경 그림이 가장자리까지 꽉 차 있어 마스크에 잘린다. Flutter(inset 16%)와 같게 줄인 판을 쓴다
        foregroundImage: './assets/icon/app_icon_foreground_inset.png',
        backgroundImage: './assets/icon/app_icon_bg.png',
      },
    },
    ios: {
      bundleIdentifier: 'app.handol.student',
      supportsTablet: false,
      ...(hasIosFirebase && { googleServicesFile: './GoogleService-Info.plist' }),
    },
    plugins: [
      'expo-router',
      ['expo-font', { fonts }],
      'expo-secure-store',
      'expo-web-browser',
      'expo-video',
      // 채널 id 는 Flutter 앱과 같다(서버 payload 가 기대하는 기본 채널)
      ['expo-notifications', { color: '#3882D3', defaultChannel: 'sandol_default' }],
      ...(hasAndroidFirebase || hasIosFirebase ? ['@react-native-firebase/app', '@react-native-firebase/analytics'] : []),
      [
        'expo-location',
        { locationWhenInUsePermission: '가까운 정류장과 건물을 찾기 위해 위치를 사용합니다.' },
      ],
      [
        '@mj-studio/react-native-naver-map',
        {
          client_id: env.NAVER_MAP_CLIENT_ID ?? '',
          android: { ACCESS_FINE_LOCATION: true, ACCESS_COARSE_LOCATION: true },
        },
      ],
      [
        'expo-build-properties',
        {
          android: {
            extraMavenRepos: ['https://repository.map.naver.com/archive/maven'],
            // R8 코드·리소스 축소. android/ 는 prebuild 로 다시 만들어지므로 여기서 고정한다.
            enableMinifyInReleaseBuilds: true,
            enableShrinkResourcesInReleaseBuilds: true,
          },
          // React Native Firebase iOS 는 정적 프레임워크가 필요하다(Windows 에서 검증 안 됨)
          ...(hasIosFirebase && { ios: { useFrameworks: 'static' } }),
        },
      ],
      './plugins/withSharedSigning',
      // Firebase 가 들어간 뒤 R8 이 기본값(2GB, Metaspace 512MB)에서 OutOfMemoryError: Metaspace 로 멈춘다
      (c) =>
        withGradleProperties(c, (cfg) => {
          const key = 'org.gradle.jvmargs';
          cfg.modResults = cfg.modResults.filter((p) => !(p.type === 'property' && p.key === key));
          cfg.modResults.push({ type: 'property', key, value: '-Xmx4g -XX:MaxMetaspaceSize=1g' });
          return cfg;
        }),
    ],
    // 값이 없으면 키를 빼 둔다(null 은 매니페스트에서 {} 로 바뀐다).
    extra: Object.fromEntries(
      Object.entries({
        apiBaseUrl: env.API_BASE_URL,
        apiFallbackBaseUrl: env.API_FALLBACK_BASE_URL,
        authIssuer: env.AUTH_ISSUER,
        authClientId: env.AUTH_CLIENT_ID,
        naverMapEnabled: Boolean(env.NAVER_MAP_CLIENT_ID),
      }).filter(([, v]) => v !== undefined && v !== ''),
    ),
  },
};
