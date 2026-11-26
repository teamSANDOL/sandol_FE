import { directionAfterPick } from '../stopPick';
import { DIRECTIONS, type ShuttleDirection } from '../model';

describe('directionAfterPick', () => {
  const dirs = Object.keys(DIRECTIONS) as ShuttleDirection[];
  test('picking the current origin keeps the direction', () => {
    for (const d of dirs) expect(directionAfterPick(d, 'origin', DIRECTIONS[d].origin)).toBe(d);
  });
  test('picking the opposite end swaps origin and destination', () => {
    for (const d of dirs) {
      const next = directionAfterPick(d, 'origin', DIRECTIONS[d].destination);
      expect(DIRECTIONS[next].origin).toBe(DIRECTIONS[d].destination);
    }
  });
});
