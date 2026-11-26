import { useEffect } from 'react';
import { Stack, usePathname } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { QueryClientProvider } from '@tanstack/react-query';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import * as WebBrowser from 'expo-web-browser';
import { AuthProvider } from '@/core/auth/AuthProvider';
import { trackScreen } from '@/core/analytics';
import { queryClient } from '@/core/query';
import { PushRegistration } from '@/features/push/PushRegistration';
import { startPush } from '@/features/push/pushService';
import { UpdatePrompt } from '@/features/update/UpdatePrompt';
import { ToastHost, colors } from '@/design-system';

WebBrowser.maybeCompleteAuthSession();

export default function RootLayout() {
  const pathname = usePathname();
  useEffect(() => startPush(), []);
  useEffect(() => trackScreen(pathname), [pathname]);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <QueryClientProvider client={queryClient}>
          <AuthProvider>
            <StatusBar style="dark" />
            <PushRegistration />
            <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: colors.background } }}>
              <Stack.Screen name="index" options={{ animation: 'none' }} />
              <Stack.Screen name="login" options={{ animation: 'fade' }} />
              <Stack.Screen name="(tabs)" options={{ animation: 'fade' }} />
              <Stack.Screen name="user" />
              <Stack.Screen name="oauthredirect" options={{ animation: 'none' }} />
            </Stack>
            <ToastHost />
            {/* 스플래시('/') 위에는 띄우지 않는다 */}
            <UpdatePrompt enabled={pathname !== '/'} />
          </AuthProvider>
        </QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
