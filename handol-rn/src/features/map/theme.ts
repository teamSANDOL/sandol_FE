import { colors } from '@/design-system';

/** 맵 탭에서만 쓰는 색 (Figma '맵' 2451:1122 계열). 공용 토큰에 없는 값만 둔다. */
export const MapColors = {
  /** 시트 · 입력창 · 칩 테두리, 시트 손잡이 */
  line: colors.border,
  /** 선택되지 않은 탭 · 보조 버튼 · 비어있는 호실 바탕 */
  soft: '#E8F0FC',
  /** 시설 아이콘 타일 바탕 */
  tile: '#ECF4FD',
  /** 수업예정 호실 바탕 · 점 (2538:17489 범례) */
  busy: '#FFE1E2',
  busyDot: '#E14045',
  /** 시트가 올라오면 지도를 덮는 막: main20 + text20 을 겹친 색 (2158:1177) */
  coverMain: 'rgba(56,130,211,0.2)',
  coverDark: 'rgba(4,4,4,0.2)',
  /** 네이버 지도를 쓸 수 없을 때의 회색 바탕 */
  mapFallback: colors.track,
  /** 비활성 시설 아이콘 투명도 (원본 SVG 가 파랑 고정이라 색 대신 흐리게) */
  disabledOpacity: 0.3,
} as const;

export const SHEET_RADIUS = 12;
