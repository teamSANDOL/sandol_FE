import { Platform, Pressable as RNPressable, type PressableProps, type StyleProp, type ViewStyle } from 'react-native';
import { colors } from '../tokens';

export type HPressableProps = Omit<PressableProps, 'style'> & {
  style?: StyleProp<ViewStyle> | ((pressed: boolean) => StyleProp<ViewStyle>);
  /** 눌렀을 때 덮는 색. 기본은 primary 8% 물결 */
  rippleColor?: string;
  borderless?: boolean;
};

/** iOS 는 물결이 없어 눌린 동안 살짝 투명하게 보인다 */
const IOS_PRESSED_OPACITY = 0.7;
const iosPressed = Platform.OS === 'ios' ? { opacity: IOS_PRESSED_OPACITY } : null;

/** Material InkWell 대응. Android 물결, iOS 눌림 투명도 */
export function HPressable({ style, rippleColor = 'rgba(56,130,211,0.12)', borderless = false, ...rest }: HPressableProps) {
  return (
    <RNPressable
      android_ripple={{ color: rippleColor, borderless, foreground: true }}
      style={({ pressed }) => [typeof style === 'function' ? style(pressed) : style, pressed && iosPressed]}
      {...rest}
    />
  );
}

export const pressFeedback = colors.field;
