import { Pressable as RNPressable, type PressableProps, type StyleProp, type ViewStyle } from 'react-native';
import { colors } from '../tokens';

export type HPressableProps = Omit<PressableProps, 'style'> & {
  style?: StyleProp<ViewStyle> | ((pressed: boolean) => StyleProp<ViewStyle>);
  /** 눌렀을 때 덮는 색. 기본은 primary 8% 물결 */
  rippleColor?: string;
  borderless?: boolean;
};

/** Material InkWell 대응. Android 물결 + 눌림 투명도 */
export function HPressable({ style, rippleColor = 'rgba(56,130,211,0.12)', borderless = false, ...rest }: HPressableProps) {
  return (
    <RNPressable
      android_ripple={{ color: rippleColor, borderless, foreground: true }}
      style={({ pressed }) => (typeof style === 'function' ? style(pressed) : style)}
      {...rest}
    />
  );
}

export const pressFeedback = colors.field;
