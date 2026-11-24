import { View } from 'react-native';
import { Icon } from './Icon';

type Props = {
  muted?: boolean;
  /** 시안 에셋은 왼쪽을 향한다. 기본은 뒤집어 오른쪽 */
  direction?: 'right' | 'left' | 'down' | 'up';
};

const ROTATION = { left: '0deg', up: '90deg', right: '180deg', down: '270deg' } as const;

/** 셰브런 (HandolChevron) */
export function Chevron({ muted = false, direction = 'right' }: Props) {
  return (
    <View style={{ transform: [{ rotate: ROTATION[direction] }] }}>
      <Icon name={muted ? 'chevronMuted' : 'chevron'} />
    </View>
  );
}
