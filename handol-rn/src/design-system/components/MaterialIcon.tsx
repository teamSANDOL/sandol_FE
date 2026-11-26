import Svg, { Path } from 'react-native-svg';
import { materialIconPaths, type MaterialIconName } from '../materialIcons';
import { colors } from '../tokens';

type Props = {
  name: MaterialIconName;
  /** Flutter Icon size (기본 24) */
  size?: number;
  color?: string;
};

/** Flutter `Icon(Icons.xxx)` 대응. 모양은 Material Icons 원본 path 그대로다. */
export function MaterialIcon({ name, size = 24, color = colors.text }: Props) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path d={materialIconPaths[name]} fill={color} />
    </Svg>
  );
}
