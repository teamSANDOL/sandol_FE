import type { TextStyle } from 'react-native';
import { colors } from './tokens';

/**
 * Pretendard 굵기별 패밀리. Android 에서 사용자 글꼴에 fontWeight 를 주면 무시되거나
 * 가짜 볼드가 되므로, 굵기는 항상 패밀리 이름으로 고른다.
 */
export const fontFamily = {
  light: 'Pretendard-Light',
  regular: 'Pretendard-Regular',
  medium: 'Pretendard-Medium',
  semibold: 'Pretendard-SemiBold',
  bold: 'Pretendard-Bold',
  black: 'Pretendard-Black',
  krub: 'Krub-Bold',
} as const;

export type FontWeightToken = Exclude<keyof typeof fontFamily, 'krub'>;

const LETTER_SPACING = -0.55;

function style(fontSize: number, lineHeight: number, weight: FontWeightToken = 'regular'): TextStyle {
  return {
    fontFamily: fontFamily[weight],
    fontSize,
    lineHeight,
    letterSpacing: LETTER_SPACING,
    color: colors.text,
    includeFontPadding: false,
  };
}

/** 새 디자인 타이포그래피 (HandolTypography) */
export const typography = {
  caption: style(14, 16),
  body: style(16, 18),
  headline: style(20, 22),
  title: style(22, 24, 'bold'),
  button: style(20, 27.5, 'bold'),
} as const;

export type TypographyVariant = keyof typeof typography;

function legacy(fontSize: number, weight: FontWeightToken): TextStyle {
  return { fontFamily: fontFamily[weight], fontSize, color: colors.text };
}

/** 옛 화면 타이포그래피 (AppTextStyles) */
export const legacyTypography = {
  display01: { ...legacy(44, 'bold'), fontVariant: ['tabular-nums'] } as TextStyle,
  display02: legacy(30, 'bold'),
  title01: legacy(24, 'bold'),
  title02: legacy(20, 'bold'),
  title03: legacy(18, 'semibold'),
  subtitle: legacy(15, 'medium'),
  body: legacy(15, 'regular'),
  number01: { ...legacy(18, 'medium'), fontVariant: ['tabular-nums'] } as TextStyle,
  number02: { ...legacy(16, 'semibold'), fontVariant: ['tabular-nums'] } as TextStyle,
  button: legacy(18, 'semibold'),
  caption01: legacy(15, 'semibold'),
  caption02: legacy(14, 'semibold'),
  caption03: legacy(14, 'regular'),
  caption04: legacy(12, 'medium'),
} as const;

/** 시안은 같은 크기에서 굵기 · 색만 바꿔 쓴다 (Flutter .strong/.muted/.accent …) */
export const tones = {
  default: colors.text,
  muted: colors.muted,
  accent: colors.primary,
  onPrimary: colors.background,
  inactive: colors.inactive,
  secondary: colors.textSecondary,
  danger: colors.red,
} as const;

export type ToneToken = keyof typeof tones;
