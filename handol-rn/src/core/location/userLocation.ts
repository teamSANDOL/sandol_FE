import { useQuery, useQueryClient } from '@tanstack/react-query';
import * as Location from 'expo-location';

export type UserPosition = { latitude: number; longitude: number };

const LOCATION_TIMEOUT_MS = 8_000;
export const userLocationKey = ['userLocation'] as const;

function withTimeout<T>(p: Promise<T>, ms: number): Promise<T> {
  return Promise.race([p, new Promise<T>((_, reject) => setTimeout(() => reject(new Error('timeout')), ms))]);
}

/** 현재 위치. 권한이 없거나 못 얻으면 null (오류로 취급하지 않는다) */
export async function fetchUserLocation(): Promise<UserPosition | null> {
  try {
    if (!(await Location.hasServicesEnabledAsync())) return null;
    let perm = await Location.getForegroundPermissionsAsync();
    if (perm.status !== 'granted' && perm.canAskAgain) {
      perm = await Location.requestForegroundPermissionsAsync();
    }
    if (perm.status !== 'granted') return null;
    try {
      const pos = await withTimeout(
        Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced }),
        LOCATION_TIMEOUT_MS,
      );
      return { latitude: pos.coords.latitude, longitude: pos.coords.longitude };
    } catch {
      // 실내 등으로 현재 위치가 늦으면 마지막 위치라도 쓴다.
      const last = await Location.getLastKnownPositionAsync();
      return last ? { latitude: last.coords.latitude, longitude: last.coords.longitude } : null;
    }
  } catch {
    return null;
  }
}

/** 당겨서 새로고침 때 위치를 다시 잡아도 되는지 (영구 거부 · 서비스 꺼짐이면 false) */
export async function canRetryLocation(): Promise<boolean> {
  try {
    if (!(await Location.hasServicesEnabledAsync())) return false;
    const perm = await Location.getForegroundPermissionsAsync();
    return perm.status === 'granted' || perm.canAskAgain;
  } catch {
    return false;
  }
}

/** 현재 위치 (앱 전역 공유 캐시). 다시 잡으려면 useRefreshUserLocation() */
export function useUserLocation() {
  return useQuery({ queryKey: userLocationKey, queryFn: fetchUserLocation, staleTime: Infinity, gcTime: Infinity, retry: false });
}

export function useRefreshUserLocation() {
  const qc = useQueryClient();
  return async () => {
    if (await canRetryLocation()) await qc.invalidateQueries({ queryKey: userLocationKey });
  };
}

/** 두 좌표 사이 거리(m), 하버사인 */
export function distanceMeters(a: UserPosition, b: UserPosition): number {
  const R = 6_371_000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.latitude - a.latitude);
  const dLon = toRad(b.longitude - a.longitude);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.latitude)) * Math.cos(toRad(b.latitude)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}
