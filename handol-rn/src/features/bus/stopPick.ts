import { DIRECTIONS, directionBetween, reversedDirection, type ShuttleDirection, type StopId } from './model';

export type StopEnd = 'origin' | 'destination';

/** 고른 정류장으로 새 방향을 만든다. 반대쪽과 같은 정류장이면 출발 · 도착을 맞바꾼다 */
export function directionAfterPick(direction: ShuttleDirection, end: StopEnd, picked: StopId): ShuttleDirection {
  const { origin, destination } = DIRECTIONS[direction];
  const next = end === 'origin' ? directionBetween(picked, destination) : directionBetween(origin, picked);
  return next ?? reversedDirection(direction);
}
