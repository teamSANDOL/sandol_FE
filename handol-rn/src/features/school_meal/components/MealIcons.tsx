import Svg, { Path } from 'react-native-svg';
import { MaterialIcon, colors } from '@/design-system';

/** Material favorite_rounded (좋아요 자리표시) */
export function HeartIcon({ size = 20, color = colors.inactive }: { size?: number; color?: string }) {
  return <MaterialIcon name="favorite" size={size} color={color} />;
}

/** 정렬 칸 아래 화살표 (Figma 2:6563, 16x9) */
export function ChevronDownIcon({ color = colors.textSecondary }: { color?: string }) {
  return (
    <Svg width={16} height={9} viewBox="0 0 16 9">
      <Path d="M1.5 1.5L8 7.5l6.5-6" stroke={color} strokeWidth={2.2} strokeLinecap="round" strokeLinejoin="round" fill="none" />
    </Svg>
  );
}
