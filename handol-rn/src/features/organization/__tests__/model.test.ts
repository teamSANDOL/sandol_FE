import {
  flattenUnits,
  formatPhone,
  parseOrganizationTree,
  pinnedUnits,
  searchOrganizationTree,
} from '../model';

const raw = {
  type: 'group',
  name: '한국공학대',
  subunits: {
    main: { type: 'unit', name: '대표', phone: '03180411000', url: 'https://tukorea.ac.kr/' },
    hq: {
      type: 'group',
      name: '대학본부',
      subunits: {
        aff: {
          type: 'group',
          name: '교무처',
          subunits: {
            a: { type: 'unit', name: '교무팀', phone: '031-8041-0013' },
            b: { type: 'unit', name: '입학관리팀', phone: '0318041-0252' },
          },
        },
        c: { type: 'unit', name: '홍보소통팀', phone: '031-8041-0295' },
        d: '문자열 노드',
      },
    },
    extra: { type: 'unit', name: '입학관리팀', phone: '000' },
  },
};

describe('parseOrganizationTree', () => {
  it('group/unit 을 재귀로 파싱하고 객체가 아닌 값은 부서로 본다', () => {
    const t = parseOrganizationTree(raw);
    expect(t.children.map((c) => c.kind)).toEqual(['unit', 'group', 'unit']);
    expect(flattenUnits(t).map((u) => u.name)).toEqual(['대표', '교무팀', '입학관리팀', '홍보소통팀', '문자열 노드', '입학관리팀']);
  });
});

describe('formatPhone', () => {
  it.each([
    ['03180411092', '031-8041-1092'],
    ['0212345678', '02-1234-5678'],
    ['0311234567', '031-123-4567'],
    ['021234567', '02-123-4567'],
    ['1234', '1234'],
  ])('%s -> %s', (i, o) => expect(formatPhone(i)).toBe(o));
});

describe('searchOrganizationTree', () => {
  const t = parseOrganizationTree(raw);
  it('공백 · 대소문자 무시 부분일치와 상위 경로', () => {
    const r = searchOrganizationTree(t, ' 교 무 ');
    expect(r.map((x) => [x.node.name, x.path])).toEqual([
      ['교무처', ['대학본부']],
      ['교무팀', ['대학본부', '교무처']],
    ]);
  });
  it('숫자만 입력하면 전화번호 숫자에도 매칭', () => {
    expect(searchOrganizationTree(t, '8041-0295'.replace('-', '')).map((x) => x.node.name)).toEqual(['홍보소통팀']);
  });
  it('빈 검색어는 빈 결과', () => expect(searchOrganizationTree(t, '  ')).toEqual([]));
});

describe('pinnedUnits', () => {
  it('고정 순서대로, 같은 이름은 먼저 나온 것, 번호 없는 부서 제외', () => {
    const t = parseOrganizationTree(raw);
    expect(pinnedUnits(t).map((u) => [u.name, u.phone])).toEqual([
      ['입학관리팀', '0318041-0252'],
      ['홍보소통팀', '031-8041-0295'],
      ['교무팀', '031-8041-0013'],
    ]);
  });
});
