import { GUEST_VALID_FOR_MS, guestAccess } from '../guestAccess';

describe('guestAccess', () => {
  test('active within 7 days, expired after, cleared on clear()', async () => {
    const t0 = Date.parse('2026-11-01T00:00:00Z');
    await guestAccess.start(t0);
    expect(await guestAccess.isActive(t0 + 1000)).toBe(true);
    expect(await guestAccess.isActive(t0 + GUEST_VALID_FOR_MS)).toBe(false);
    expect(await guestAccess.isActive(t0 - 1000)).toBe(false);
    await guestAccess.clear();
    expect(await guestAccess.isActive(t0 + 1000)).toBe(false);
  });
});
