import type { SvgProps } from 'react-native-svg';
import { icons, type IconName } from '../assets';

export type IconProps = SvgProps & {
  name: IconName;
  /** 정사각 크기. 주지 않으면 SVG 원래 크기 */
  size?: number;
};

/** 시안 SVG 아이콘. color 는 currentColor 를 쓰는 아이콘에만 효과가 있다. */
export function Icon({ name, size, width, height, ...rest }: IconProps) {
  const Svg = icons[name];
  // undefined 를 넘기면 SVG 의 원래 width/height 를 덮어써 부모 폭으로 늘어난다. 정해진 값만 넘긴다.
  const w = size ?? width;
  const h = size ?? height;
  return <Svg {...rest} {...(w !== undefined ? { width: w } : null)} {...(h !== undefined ? { height: h } : null)} />;
}
