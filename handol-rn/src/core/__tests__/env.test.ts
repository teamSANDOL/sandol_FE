import { usesLegacyScheme } from '../env';

describe('usesLegacyScheme', () => {
  it('0.3.23 까지는 옛 스킴, 0.3.24 부터 새 스킴', () => {
    expect(['0.3.21', '0.3.23', '0.2.9'].map(usesLegacyScheme)).toEqual([true, true, true]);
    expect(['0.3.24', '0.4.0', '1.0.0'].map(usesLegacyScheme)).toEqual([false, false, false]);
  });
});
