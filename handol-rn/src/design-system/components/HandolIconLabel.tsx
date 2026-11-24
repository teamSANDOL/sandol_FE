import type { ReactNode } from 'react';
import { View, type TextStyle } from 'react-native';
import { spacing } from '../tokens';
import type { ToneToken, TypographyVariant, FontWeightToken } from '../typography';
import { HText } from './HText';
import { Icon } from './Icon';

type Props = {
  icon: ReactNode;
  label: string;
  variant?: TypographyVariant;
  weight?: FontWeightToken;
  tone?: ToneToken;
  textStyle?: TextStyle;
  gap?: number;
  /** 기본 한 줄 말줄임. null 이면 줄바꿈 허용 */
  numberOfLines?: number | null;
  keepAll?: boolean;
};

/** 아이콘 + 글자 한 줄. 시계 · 정류장 · 출발 시각 · 안내 줄 (HandolIconLabel) */
export function HandolIconLabel({
  icon,
  label,
  variant = 'caption',
  weight,
  tone,
  textStyle,
  gap = spacing.sm,
  numberOfLines = 1,
  keepAll,
}: Props) {
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', flexShrink: 1 }}>
      {icon}
      <View style={{ width: gap }} />
      <HText
        variant={variant}
        weight={weight}
        tone={tone}
        style={[{ flexShrink: 1 }, textStyle]}
        numberOfLines={numberOfLines ?? undefined}
        keepAll={keepAll}
      >
        {label}
      </HText>
    </View>
  );
}

/** ⓘ + 흐린 캡션. 보조 안내 문구 (HandolIconLabel.note) */
export function HandolNote({ text }: { text: string }) {
  return <HandolIconLabel icon={<Icon name="info" />} label={text} tone="muted" gap={6} numberOfLines={null} keepAll />;
}
