import { useEffect, useState } from 'react';
import { Linking, Platform } from 'react-native';
import * as Application from 'expo-application';
import * as Updates from 'expo-updates';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { env } from '@/core/env';
import { ConfirmDialog } from '@/features/user/components/ConfirmDialog';
import { isNewerVersion, parseVersion } from './version';

/** '나중에' 누른 설치 파일 버전. 그보다 새 버전이 나와야 다시 묻는다 */
const DISMISSED_KEY = 'update.dismissedRelease';
const FETCH_TIMEOUT_MS = 5000;

type Release = { tag: string; url: string };

/** Gitea 최신 릴리스 태그. 실패하면 null (업데이트 안내는 부가 기능이라 앱 사용을 막지 않는다) */
async function fetchLatestRelease(): Promise<Release | null> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), FETCH_TIMEOUT_MS);
  try {
    const res = await fetch(env.appReleasesApi, { signal: ctrl.signal });
    if (!res.ok) return null;
    const list: unknown = await res.json();
    const tag = Array.isArray(list) ? (list[0] as { tag_name?: unknown } | undefined)?.tag_name : undefined;
    if (typeof tag !== 'string' || !parseVersion(tag)) return null;
    return { tag, url: env.appReleasePage + encodeURIComponent(tag) };
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

/**
 * 업데이트 안내 팝업. 두 가지를 본다.
 * 1. OTA: 새 JS 번들을 받아 두었으면(다음 실행에 적용 대기) 지금 다시 시작해 적용할지 묻는다.
 * 2. 설치 파일: Gitea 에 지금보다 새 버전 APK 가 올라왔으면 릴리스 페이지로 안내한다(Android).
 *    OTA 로는 네이티브(권한·라이브러리) 변경을 보낼 수 없어 새 설치 파일이 필요하다.
 * enabled 가 false(스플래시 등)인 동안은 띄우지 않는다.
 */
export function UpdatePrompt({ enabled }: { enabled: boolean }) {
  const { isUpdatePending } = Updates.useUpdates();
  const [otaDismissed, setOtaDismissed] = useState(false);
  const [release, setRelease] = useState<Release | null>(null);

  useEffect(() => {
    if (__DEV__ || Platform.OS !== 'android') return;
    const current = Application.nativeApplicationVersion ?? '';
    let alive = true;
    void (async () => {
      const latest = await fetchLatestRelease();
      if (!alive || !latest || !isNewerVersion(latest.tag, current)) return;
      if ((await AsyncStorage.getItem(DISMISSED_KEY)) === latest.tag) return;
      if (alive) setRelease(latest);
    })();
    return () => {
      alive = false;
    };
  }, []);

  const showOta = enabled && isUpdatePending && !otaDismissed;
  const showRelease = enabled && !showOta && release !== null;

  const closeRelease = () => {
    if (release) void AsyncStorage.setItem(DISMISSED_KEY, release.tag);
    setRelease(null);
  };

  return (
    <>
      <ConfirmDialog
        visible={showOta}
        tone="primary"
        icon="update"
        title="새 버전이 준비됐어요"
        message="앱을 다시 시작하면 새 버전이 적용돼요."
        cancelLabel="나중에"
        confirmLabel="지금 적용"
        onCancel={() => setOtaDismissed(true)}
        onConfirm={() => void Updates.reloadAsync().catch(() => setOtaDismissed(true))}
      />
      <ConfirmDialog
        visible={showRelease}
        tone="primary"
        icon="update"
        title="새 버전이 나왔어요"
        message={`한돌이 ${release?.tag ?? ''}을 설치해 주세요. 새 기능과 수정 사항이 담겨 있어요.`}
        cancelLabel="나중에"
        confirmLabel="업데이트"
        onCancel={closeRelease}
        onConfirm={() => {
          if (release) void Linking.openURL(release.url);
          closeRelease();
        }}
      />
    </>
  );
}
