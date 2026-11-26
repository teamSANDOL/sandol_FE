/**
 * Firebase Messaging 은 iOS 에서 FCM 토큰을 받는 데만 쓴다(src/features/push/pushService.ts).
 * Android 는 expo-notifications 가 FCM 수신·표시를 맡으므로 링크하지 않는다(수신 서비스가 겹친다).
 */
module.exports = {
  dependencies: {
    '@react-native-firebase/messaging': { platforms: { android: null } },
  },
};
