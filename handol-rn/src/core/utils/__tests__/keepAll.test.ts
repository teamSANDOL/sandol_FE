import { breakHangul, keepAll } from '../keepAll';

test('inserts word joiners only inside words', () => {
  const out = keepAll('한돌 앱');
  expect(out).toBe('한\u2060돌 앱');
  expect(out.replace(/\u2060/g, '')).toBe('한돌 앱');
});

test('breakHangul allows breaks only between Hangul syllables', () => {
  const out = breakHangul('한돌 AB12 셔틀');
  expect(out).toBe('한\u200B돌 AB12 셔\u200B틀');
  expect(out.replace(/\u200B/g, '')).toBe('한돌 AB12 셔틀');
});
