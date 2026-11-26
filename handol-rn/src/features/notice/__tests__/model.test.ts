import { filterNotices, isNewNotice, kstDateOf, nextSeen, titleWithoutAuthor, type Notice } from '../model';

const n = (over: Partial<Notice>): Notice => ({
  id: 1, url: 'https://x', title: '제목', author: '학사지원팀', createdAt: '2026-11-23T10:00:00', ...over,
});

describe('notice model', () => {
  it('filters by keyword, general and query', () => {
    const items = [
      n({ id: 1, title: '수강신청 안내', author: '학사지원팀' }),
      n({ id: 2, title: '국가장학금 신청', author: '학생처' }),
      n({ id: 3, title: '도서관 휴관', author: '도서관' }),
    ];
    expect(filterNotices(items, 'academic').map((x) => x.id)).toEqual([1]);
    expect(filterNotices(items, 'scholarship').map((x) => x.id)).toEqual([2]);
    expect(filterNotices(items, 'general').map((x) => x.id)).toEqual([3]);
    expect(filterNotices(items, 'all', ' 도서 ').map((x) => x.id)).toEqual([3]);
    expect(filterNotices(items, 'dormitory')).toHaveLength(3);
  });

  it('strips a duplicated [author] prefix from the title', () => {
    expect(titleWithoutAuthor(n({ title: '[학사지원팀] 안내' }))).toBe('안내');
    expect(titleWithoutAuthor(n({ title: '[학사지원팀]' }))).toBe('[학사지원팀]');
    expect(titleWithoutAuthor(n({ title: '안내' }))).toBe('안내');
  });

  it('reads the KST date of createdAt', () => {
    expect(kstDateOf('2026-11-23T10:00:00')).toBe('2026-11-23');
    expect(kstDateOf('2026-11-23T20:00:00Z')).toBe('2026-11-24');
    expect(kstDateOf('2026-11-23')).toBe('2026-11-23');
    expect(kstDateOf('nope')).toBeNull();
  });

  it('marks NEW only for recent unseen notices', () => {
    const cutoff = '2026-11-22';
    const recent = n({ id: 5, createdAt: '2026-11-23T01:00:00' });
    expect(isNewNotice(recent, null, cutoff)).toBe(true);
    expect(isNewNotice(recent, { '5': '2026-11-23' }, cutoff)).toBe(false);
    expect(isNewNotice(n({ createdAt: '2026-11-20T01:00:00' }), null, cutoff)).toBe(false);
    expect(isNewNotice(n({ createdAt: 'bad' }), null, cutoff)).toBe(false);
  });

  it('records seen notices and drops expired keys', () => {
    const next = nextSeen({ old: '2026-11-01', keep: '2026-11-22' }, [n({ id: 7 }), n({ id: 8, createdAt: '2026-10-01T00:00:00' })], '2026-11-22');
    expect(next).toEqual({ keep: '2026-11-22', '7': '2026-11-23' });
  });
});
