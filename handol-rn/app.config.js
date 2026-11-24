const fs = require('fs');
const path = require('path');

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
const fonts = ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold', 'Black']
  .map((w) => `./assets/fonts/Pretendard-${w}.otf`)
  .concat('./assets/fonts/Krub-Bold.ttf');

module.exports = {
  expo: {
    name: '한돌이',
    slug: 'handol',
    // Keycloak 로그인 딥링크(kr.sandori.handori://oauthredirect)와 같은 스킴
    scheme: 'kr.sandori.handori',
    version: '0.3.18',
    orientation: 'portrait',
    icon: './assets/icon/app_icon.png',
    // 화면 색이 토큰으로 고정돼 있어 다크 모드를 지원하지 않는다(Flutter 와 동일).
    userInterfaceStyle: 'light',
    backgroundColor: '#FDFDFD',
    android: {
      // 네이버 지도 키가 패키지명에 묶여 있어 Flutter 앱과 같은 ID 를 쓴다.
      package: 'app.handol.student',
      versionCode: 3018,
      adaptiveIcon: {
        foregroundImage: './assets/icon/app_icon_foreground.png',
        backgroundImage: './assets/icon/app_icon_bg.png',
      },
    },
    ios: { bundleIdentifier: 'app.handol.student', supportsTablet: false },
    plugins: [
      'expo-router',
      ['expo-font', { fonts }],
      'expo-secure-store',
      'expo-web-browser',
      'expo-video',
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
          },
        },
      ],
      './plugins/withSharedSigning',
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
