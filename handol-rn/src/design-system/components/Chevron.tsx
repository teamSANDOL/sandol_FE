import { View } from 'react-native';
import { colors } from '../tokens';
import { Icon } from './Icon';

type Props = {
  /** 흐린 셰브런 (기본 text 50%) */
  muted?: boolean;
  /** 시안 에셋은 왼쪽을 향한다. 기본은 뒤집어 오른쪽 */
  direction?: 'right' | 'left' | 'down' | 'up';
  /**
   * 색을 바꾼다. 어두운 바탕 위(홈 '전체학과/ 부서 조회' 줄)는 흰색, 마이페이지 목록은
   * border(#D5DAE5) · text20 처럼 화면마다 시안 색이 다르다.
   */
  color?: string;
};

const ROTATION = { left: '0deg', up: '90deg', right: '180deg', down: '270deg' } as const;
/** 시안 chevron 에셋의 원래 색 (2153:382) */
const DEFAULT_COLOR = '#12131A';

/** 셰브런 (HandolChevron) */
export function Chevron({ muted = false, direction = 'right', color }: Props) {
  return (
    <View style={{ transform: [{ rotate: ROTATION[direction] }] }}>
      <Icon name={muted ? 'chevronMuted' : 'chevron'} color={color ?? (muted ? colors.muted : DEFAULT_COLOR)} />
    </View>
  );
}
