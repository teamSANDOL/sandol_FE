import { useEffect, useState } from 'react';
import { StyleSheet, useWindowDimensions, View } from 'react-native';
import { Image } from 'expo-image';
import { router } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import { createVideoPlayer, VideoView, type VideoPlayer } from 'expo-video';
import { useAuth } from '@/core/auth/AuthProvider';
import { guestAccess } from '@/core/auth/guestAccess';
import { colors, images } from '@/design-system';
import { discardPendingPush } from '@/features/push/pushService';
import { prefetchHome } from '../prefetchHome';
import { splashTarget, type SplashTarget } from '../splashRoute';

/** Figma 원본 1080×1920. 영상도 같은 크기라 정지 이미지 위에 그대로 덮는다 */
const ART_ASPECT = 1080 / 1920;

/**
 * 스플래시. 세션 복원이 끝나면 영상을 기다리지 않고 홈 또는 로그인으로 넘어간다.
 * 영상은 반복하지 않고 끝나면 마지막 프레임에 머문다. 실패하면 정지 이미지가 남는다.
 */
export default function SplashScreen() {
  const { status } = useAuth();
  const { width } = useWindowDimensions();
  const [target, setTarget] = useState<SplashTarget | null>(null);
  const queryClient = useQueryClient();

  useEffect(() => {
    if (status === 'restoring') return;
    let isCancelled = false;
    void (async () => {
      const next = splashTarget(status, await guestAccess.isActive());
      if (!next) return;
      // 홈으로 가면 첫 화면 데이터를 받아 두고(최대 5초), 로그인으로 가면 알림으로 열 화면을 버린다.
      if (next === '/home') await prefetchHome(queryClient);
      else discardPendingPush();
      if (!isCancelled) setTarget(next);
    })();
    return () => {
      isCancelled = true;
    };
  }, [status]);

  // 영상 층(플레이어 + 뷰)을 먼저 내린 다음 렌더에서 화면을 바꾼다. 둘을 한 컴포넌트가 함께 해제해야
  // "이미 해제된 player 를 뷰에 붙이는" 순서 오류가 나지 않는다.
  useEffect(() => {
    if (target) router.replace(target);
  }, [target]);

  return (
    <View style={styles.root}>
      <View style={{ width, aspectRatio: ART_ASPECT }}>
        <Image source={images.splashPoster} contentFit="contain" style={StyleSheet.absoluteFill} accessibilityLabel="한돌이 시작 화면" />
        {/* 첫 프레임이 그려지면 영상 층을 보인다 */}
        {target === null && <SplashVideo />}
      </View>
    </View>
  );
}

/** 스플래시 영상. 플레이어와 뷰를 이 컴포넌트가 함께 만들고 함께 해제한다 */
/** 뷰가 완전히 내려간 뒤 플레이어를 해제한다. 바로 해제하면 네이티브 뷰가 해제된 player 를 다시 받으며 오류가 난다 */
const RELEASE_DELAY_MS = 1000;

function useSplashPlayer(): VideoPlayer {
  const [player] = useState(() => {
    const p = createVideoPlayer(images.splashVideo);
    p.loop = false;
    p.muted = true;
    // 다른 앱의 음악을 끊지 않게 섞어 튼다
    p.audioMixingMode = 'mixWithOthers';
    p.play();
    return p;
  });
  useEffect(
    () => () => {
      player.pause();
      setTimeout(() => player.release(), RELEASE_DELAY_MS);
    },
    [player],
  );
  return player;
}

function SplashVideo() {
  const [isReady, setIsReady] = useState(false);
  const player = useSplashPlayer();
  return (
    <VideoView
      player={player}
      contentFit="contain"
      nativeControls={false}
      onFirstFrameRender={() => setIsReady(true)}
      style={[StyleSheet.absoluteFill, { opacity: isReady ? 1 : 0 }]}
    />
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.background, alignItems: 'center', justifyContent: 'center' },
});
