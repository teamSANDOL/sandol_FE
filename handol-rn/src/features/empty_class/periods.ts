/**
 * 교시 시간표 (0시 기준 분). 백엔드 /classrooms/available/periods 가 교시를 시각으로 바꿀 때
 * 쓰는 표와 같다. 9교시부터 야간이라 간격이 다르다.
 */
export interface ClassPeriod {
  start: number;
  end: number;
}

const hm = (h: number, m: number): number => h * 60 + m;

export const classPeriods: readonly ClassPeriod[] = [
  { start: hm(9, 30), end: hm(10, 20) }, // 1
  { start: hm(10, 30), end: hm(11, 20) },
  { start: hm(11, 30), end: hm(12, 20) },
  { start: hm(12, 30), end: hm(13, 20) },
  { start: hm(13, 30), end: hm(14, 20) },
  { start: hm(14, 30), end: hm(15, 20) },
  { start: hm(15, 30), end: hm(16, 20) },
  { start: hm(16, 30), end: hm(17, 20) }, // 8
  { start: hm(17, 25), end: hm(18, 15) },
  { start: hm(18, 15), end: hm(19, 5) },
  { start: hm(19, 5), end: hm(19, 55) },
  { start: hm(20, 0), end: hm(20, 50) },
  { start: hm(20, 50), end: hm(21, 40) },
  { start: hm(21, 40), end: hm(22, 30) }, // 14
];

/** 1교시 시작 ~ 14교시 끝. 교시 선택의 '전체 교시'. */
export const allPeriods: ClassPeriod = {
  start: classPeriods[0].start,
  end: classPeriods[classPeriods.length - 1].end,
};

/**
 * 조회 구간이 가리키는 교시 문구. 한 교시와 정확히 같으면 `N교시`, 전체면 `전체 교시`,
 * 그 외(시각으로 고른 구간)는 null.
 */
export function periodLabelOf(startMinutes: number, endMinutes: number): string | null {
  if (startMinutes === allPeriods.start && endMinutes === allPeriods.end) return '전체 교시';
  const i = classPeriods.findIndex((p) => p.start === startMinutes && p.end === endMinutes);
  return i < 0 ? null : `${i + 1}교시`;
}
