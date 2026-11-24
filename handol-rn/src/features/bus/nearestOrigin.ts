import { distanceMeters, type UserPosition } from '@/core/location/userLocation';
import { STOP_IDS, type ShuttleDirection, type ShuttleStops } from './model';

/**
 * 현재 위치에서 가장 가까운 정류장을 출발지로 하는 방향. 좌표 없는 정류장은 판정에서 뺀다.
 * 학교 · 정왕역이면 정왕역 노선, 제2캠퍼스면 본교행. 좌표가 하나도 없으면 학교 출발.
 */
export function nearestShuttleDirection(pos: UserPosition, stops: ShuttleStops): ShuttleDirection {
  let nearest: string | null = null;
  let best = Infinity;
  for (const id of STOP_IDS) {
    const { lat, lng } = stops[id] ?? {};
    if (lat == null || lng == null) continue;
    const d = distanceMeters(pos, { latitude: lat, longitude: lng });
    if (d < best) {
      nearest = id;
      best = d;
    }
  }
  if (nearest === 'jeongwang') return 'jeongwangToSchool';
  if (nearest === 'campus2') return 'campus2ToSchool';
  return 'schoolToJeongwang';
}
