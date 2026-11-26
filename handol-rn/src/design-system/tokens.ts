/**
 * 한돌이 디자인 토큰 (Flutter lib/core/design_system/handol_tokens.dart 이식).
 * 화면에서 색·간격·반지름 값을 직접 쓰지 말고 여기서 가져다 쓴다.
 */

/** Figma 2142:2334 / 2143:2498 / 2143:2581 / 2143:2624 공통 색 */
export const colors = {
  primary: '#3882D3',
  background: '#FDFDFD',
  text: '#040404',
  /** text 50% */
  muted: 'rgba(4,4,4,0.5)',
  /** primary 20% */
  field: 'rgba(56,130,211,0.2)',
  /** 카드 · 입력 필드 공용 테두리 */
  border: '#D5DAE5',
  fieldBorder: '#D5DAE5',
  link: 'rgba(56,130,211,0.8)',
  error: '#D63B3B',
  /** field 를 배경 위에 합성한 불투명 값 */
  primarySoft: '#D5E4F4',
  /** 슬라이더의 선택되지 않은 트랙 */
  track: '#E2E2E2',
  /** 지나간 시각 · 비활성 버튼 (Figma 2156:516) */
  inactive: '#A4ABBD',
  /** 본문보다 한 단계 약한 진회색 (Figma 2156:483) */
  textSecondary: '#404756',
  /** 시간표 '수시 운행' 배지 (Figma 2683:3198) */
  orange: '#D97745',
  /** MAIN RED. 되돌릴 수 없는 동작 */
  red: '#C9273F',
  /** 꺼진 토글 바탕 (text 20%) */
  text20: 'rgba(4,4,4,0.2)',
  white: '#FFFFFF',
  transparent: 'transparent',
} as const;

/**
 * 옛 화면 팔레트 (lib/core/constants/app_colors.dart). 아직 새 시안으로 바뀌지 않은
 * 화면(오류 뷰, 일부 상태 배지)이 쓴다.
 */
export const legacyColors = {
  primary: '#0088CC',
  primaryLight: '#E6F9FF',
  primaryBorder: '#BDE8F6',
  background: '#FAFAFA',
  surface: '#FFFFFF',
  subtleBg: '#F7FBFD',
  cardBorder: '#E2EEF3',
  divider: '#F0F0F8',
  textPrimary: '#1A1A1A',
  textSecondary: '#6B7A89',
  textMuted: '#8A8F98',
  success: '#2F8C3B',
  warning: '#FFB74D',
  danger: '#D63B3B',
} as const;

export const spacing = { xs: 4, sm: 8, md: 16, lg: 24, xl: 40 } as const;

/** 앱 전체 모서리 반지름은 12 하나 (AppRadius) */
export const radius = { md: 12, lg: 16, pill: 999 } as const;

export const metrics = {
  referenceWidth: 412,
  contentWidth: 346,
  pageGutter: 33,
  /** 카드 안쪽 좌우 여백 */
  cardInset: 20,
  logoSize: 160,
  iconSize: 24,
  buttonHeight: 44,
  topBarHeight: 56,
  bottomNavHeight: 70,
} as const;

/**
 * 카드 그림자. primary 10%, Figma blur 4 / y 4. Flutter blurRadius 4 는
 * CSS blur 약 6 으로 렌더되므로 그 값에 맞춘다.
 */
export const shadows = {
  card: { boxShadow: '0px 4px 6px rgba(56, 130, 211, 0.1)' },
} as const;

/**
 * 화면 · 카드 그라데이션. Flutter Alignment(-1..1) 를 expo-linear-gradient 의
 * 0..1 좌표로 옮긴 값이다.
 */
export const gradients = {
  /**
   * 화면 배경 (홈_re 2:4325, 학식-2 2:6397). 바탕은 background 단색이고, 맨 아래에만
   * 보라 원(Ellipse 12, #8B7CF6 10%, 레이어 블러 300)이 아주 옅게 번진다.
   * Figma 렌더를 재 보면 아래 300dp 에서 #FDFDFD → #F9F8FD 로 바뀌므로 그 구간만 칠한다.
   */
  screen: {
    colors: ['rgba(139,124,246,0)', 'rgba(139,124,246,0.045)'] as const,
    locations: [0, 1] as const,
    height: 300,
    start: { x: 0.5, y: 0 },
    end: { x: 0.5, y: 1 },
  },
  /**
   * 홈 기능 소개 배너 (Frame 2147234779). 시안(primary → #5FA8EA)이 너무 진해
   * 두 색을 흰색과 25% 섞어 흐리게 했다.
   */
  primaryCard: {
    colors: ['#6AA1DE', '#87BEEF'] as const,
    locations: [0, 1] as const,
    start: { x: 0.70145, y: 1.73495 },
    end: { x: -0.0862, y: -0.2132 },
  },
} as const;

export type ColorToken = keyof typeof colors;
