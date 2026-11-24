const fs = require('fs');
const path = require('path');
const { withAppBuildGradle } = require('expo/config-plugins');

/**
 * Flutter 앱과 같은 서명 키(저장소 루트 android/key.properties)로 debug·release 를
 * 서명한다. 그래야 기존 설치본 위에 데이터를 지우지 않고 덮어쓸 수 있다.
 * key.properties 가 없으면 Expo 기본 debug.keystore 를 그대로 쓴다.
 */
module.exports = function withSharedSigning(config) {
  return withAppBuildGradle(config, (cfg) => {
    const keyDir = path.resolve(__dirname, '..', '..', 'android');
    const propsFile = path.join(keyDir, 'key.properties');
    if (!fs.existsSync(propsFile)) return cfg;
    const marker = '// shared-signing';
    if (cfg.modResults.contents.includes(marker)) return cfg;
    const keyDirGradle = keyDir.replace(/\\/g, '/');
    const block = `
    signingConfigs {
        ${marker}
        def sharedProps = new Properties()
        file("${keyDirGradle}/key.properties").withInputStream { sharedProps.load(it) }
        debug {
            storeFile file("${keyDirGradle}/" + sharedProps['storeFile'])
            storePassword sharedProps['storePassword']
            keyAlias sharedProps['keyAlias']
            keyPassword sharedProps['keyPassword']
        }
    }`;
    cfg.modResults.contents = cfg.modResults.contents.replace(
      /\n\s*signingConfigs \{\s*\n\s*debug \{[\s\S]*?\}\s*\n\s*\}/,
      block,
    );
    return cfg;
  });
};
