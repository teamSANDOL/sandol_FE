const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// 시안 SVG 를 컴포넌트로 불러온다(react-native-svg-transformer).
config.transformer = {
  ...config.transformer,
  babelTransformerPath: require.resolve('react-native-svg-transformer/expo'),
};
config.resolver = {
  ...config.resolver,
  assetExts: config.resolver.assetExts.filter((ext) => ext !== 'svg'),
  sourceExts: [...config.resolver.sourceExts, 'svg'],
};

module.exports = config;
