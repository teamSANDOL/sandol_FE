import type { ReactNode } from 'react';
import { View } from 'react-native';
import { HPressable } from './Pressable';

type Props = {
  icon: ReactNode;
  /** 접근성 라벨 (Flutter tooltip) */
  label: string;
  onPress?: () => void;
  background?: string;
  /** 배경 원 지름. 없으면 아이콘 크기를 따른다 */
  size?: number;
};

/** 원형 아이콘 버튼. 시안 SVG 에 원 배경이 있으면 background 를 비운다 (HandolIconButton) */
export function HandolIconButton({ icon, label, onPress, background = 'transparent', size }: Props) {
  return (
    <View style={{ borderRadius: 999, overflow: 'hidden', backgroundColor: background }}>
      <HPressable
        accessibilityRole="button"
        accessibilityLabel={label}
        disabled={!onPress}
        onPress={onPress}
        style={{ width: size, height: size, alignItems: 'center', justifyContent: 'center' }}
      >
        {icon}
      </HPressable>
    </View>
  );
}
