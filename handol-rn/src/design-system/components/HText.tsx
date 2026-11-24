import { Platform, StyleSheet, Text, type TextProps, type TextStyle } from 'react-native';
import type { ReactNode } from 'react';
import { breakHangul, keepAll as applyKeepAll } from '@/core/utils/keepAll';
import {
  fontFamily,
  legacyTypography,
  tones,
  typography,
  type FontWeightToken,
  type ToneToken,
  type TypographyVariant,
} from '../typography';

export interface HTextProps extends TextProps {
  /** 새 디자인 타이포그래피 단계 */
  variant?: TypographyVariant;
  /** 옛 화면 타이포그래피 단계. 주면 variant 보다 우선한다. */
  legacy?: keyof typeof legacyTypography;
  /** 같은 단계에서 굵기만 바꾼다 (Flutter .strong = bold) */
  weight?: FontWeightToken;
  /** 같은 단계에서 색만 바꾼다 */
  tone?: ToneToken;
  /** 어절 단위 줄바꿈. 기본은 Flutter 처럼 한글 음절 사이 어디서든 줄을 바꾼다 */
  keepAll?: boolean;
  style?: TextStyle | TextStyle[] | (TextStyle | false | undefined | null)[];
}

/** 디자인 시스템 텍스트. 화면에서 fontSize · fontFamily 를 직접 쓰지 않는다. */
export function HText({
  variant = 'body',
  legacy,
  weight,
  tone,
  keepAll,
  style,
  children,
  ...rest
}: HTextProps) {
  const base = legacy ? legacyTypography[legacy] : typography[variant];
  // 한 줄 고정 텍스트는 줄바꿈 규칙이 필요 없다. 폭 0 공백이 가운데 정렬 폭 계산을 흐트러뜨리므로 넣지 않는다.
  const isSingleLine = rest.numberOfLines === 1;
  const wrap = keepAll ? applyKeepAll : isSingleLine ? null : breakHangul;
  const content = wrap ? mapStrings(children, wrap) : children;
  const flat: TextStyle = StyleSheet.flatten([
    base,
    weight ? { fontFamily: fontFamily[weight] } : null,
    tone ? { color: tones[tone] } : null,
    style as TextStyle,
  ]) ?? {};
  return (
    <Text
      allowFontScaling
      maxFontSizeMultiplier={1.4}
      lineBreakStrategyIOS={keepAll && Platform.OS === 'ios' ? 'hangul-word' : undefined}
      {...rest}
      style={[flat, keepAllSpacing(flat, content), trailingSpacing(flat)]}
    >
      {content}
    </Text>
  );
}


/** 문자열 자식(배열 포함)에만 줄바꿈 규칙을 적용한다. 중첩 Text 는 자기 규칙을 따른다 */
function mapStrings(children: ReactNode, fn: (s: string) => string): ReactNode {
  if (typeof children === 'string') return fn(children);
  if (Array.isArray(children)) return children.map((c) => (typeof c === 'string' ? fn(c) : c));
  return children;
}

/**
 * Flutter 는 keepAll 이 끼운 WORD JOINER 에도 자간을 적용해 글이 그만큼 좁아진다. Android 는 그 문자에
 * 자간을 주지 않으므로, 줄어든 총량을 글자들에 고르게 나눠 같은 폭이 되게 한다.
 */
function keepAllSpacing(s: TextStyle, content: ReactNode): TextStyle | null {
  const ls = typeof s.letterSpacing === 'number' ? s.letterSpacing : 0;
  const text = typeof content === 'string' ? content : Array.isArray(content) && content.every((c) => typeof c === 'string') ? content.join('') : null;
  if (ls === 0 || text === null) return null;
  const chars = Array.from(text);
  const joiners = chars.filter((c) => c === '\u2060').length;
  const visible = chars.length - joiners;
  if (joiners === 0 || visible < 2) return null;
  // 글자 사이(visible - 1 칸)에 들어가는 자간 총량이 Flutter(글자 사이 + 끼운 문자 몫)와 같아지게 한다
  return { letterSpacing: (ls * (visible - 1 + joiners)) / (visible - 1) };
}

/**
 * Flutter 는 마지막 글자 뒤에도 자간을 붙여 텍스트 상자가 그만큼 좁다(음수 자간이면 더 좁다).
 * Android 는 마지막 글자 뒤에는 붙이지 않으므로, 음수 자간만큼 오른쪽 마진을 당겨 상자 폭을 맞춘다.
 */
function trailingSpacing(s: TextStyle): TextStyle | null {
  const ls = typeof s.letterSpacing === 'number' ? s.letterSpacing : 0;
  if (ls >= 0 || s.marginRight !== undefined || s.marginHorizontal !== undefined || s.margin !== undefined) return null;
  return { marginRight: ls };
}
