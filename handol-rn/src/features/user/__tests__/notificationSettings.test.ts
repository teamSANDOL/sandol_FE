import { DEFAULT_NOTIFICATION_SETTINGS, mergeStored } from '../notificationSettings';

describe('mergeStored', () => {
  it('저장값이 없으면 현재 값을 유지한다', () => {
    expect(mergeStored({ ...DEFAULT_NOTIFICATION_SETTINGS, marketing: true }, { push: null })).toEqual({ push: true, benefit: true, marketing: true });
  });
  it('저장된 문자열 true/false 를 불리언으로 바꾼다', () => {
    expect(mergeStored(DEFAULT_NOTIFICATION_SETTINGS, { push: 'false', marketing: 'true' })).toEqual({ push: false, benefit: true, marketing: true });
  });
});
