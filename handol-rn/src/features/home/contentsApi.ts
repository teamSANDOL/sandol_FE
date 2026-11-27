import { Platform } from 'react-native';
import * as Application from 'expo-application';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useQuery } from '@tanstack/react-query';
import { api } from '@/core/api/client';
import { env } from '@/core/env';
import { homeBanners } from './banners';
import { parseServerBanners, type HomeBanner } from './model';

const CACHE_KEY = 'home.banners';
export const HOME_BANNERS_KEY = ['home', 'banners'];

/**
 * 홈 배너 (BFF GET /app/v1/contents). 서버가 게시 기간·플랫폼·빌드로 걸러 준다.
 * 실패하면 마지막으로 받은 목록, 그것도 없으면 앱 내장 목록. 그래서 이 쿼리는 실패하지 않는다.
 */
export async function fetchHomeBanners(): Promise<readonly HomeBanner[]> {
  try {
    const res = await api.get<{ home_banners?: unknown } | null>(`${env.bffBaseUrl}/app/v1/contents`, {
      auth: false,
      query: { platform: Platform.OS, app_version: Application.nativeApplicationVersion, build: Number(Application.nativeBuildVersion) || undefined },
    });
    const raw = res?.home_banners ?? [];
    void AsyncStorage.setItem(CACHE_KEY, JSON.stringify(raw)).catch(() => undefined);
    return parseServerBanners(raw, env.bffBaseUrl);
  } catch {
    const cached = await AsyncStorage.getItem(CACHE_KEY).catch(() => null);
    // 저장본은 그 사이 ends_at 이 지난 배너를 parseServerBanners 가 뺀다
    if (!cached) return homeBanners;
    try {
      return parseServerBanners(JSON.parse(cached), env.bffBaseUrl);
    } catch {
      return homeBanners;
    }
  }
}

export function useHomeBanners(): readonly HomeBanner[] {
  return useQuery({ queryKey: HOME_BANNERS_KEY, queryFn: fetchHomeBanners, staleTime: 5 * 60_000 }).data ?? [];
}
