import Svg, { Path } from 'react-native-svg';
import { MaterialIcon, colors } from '@/design-system';

type Props = { size?: number; color?: string };

/** 공지 화면의 Material 아이콘 (Flutter notice_page / notice_card / notice_detail_page 와 같은 변형) */
export const SearchIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="search" size={size} color={color} />;
export const TuneIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="tune" size={size} color={color} />;
export const CloseIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="close" size={size} color={color} />;
export const BookmarkIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="bookmark" size={size} color={color} />;
export const BookmarkBorderIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="bookmarkBorder" size={size} color={color} />;
/** 정렬 칸 아래 화살표 (Figma 2:6100, 14x8) */
export const ChevronDownIcon = ({ color = colors.text }: { color?: string }) => (
  <Svg width={14} height={8} viewBox="0 0 14 8">
    <Path d="M1.2 1.2L7 6.8l5.8-5.6" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" fill="none" />
  </Svg>
);
/** 카드 오른쪽 화살표 (Figma 2:2996, 8x14) */
export const ChevronRightIcon = ({ color = colors.text }: { color?: string }) => (
  <Svg width={8} height={14} viewBox="0 0 8 14">
    <Path d="M1.2 1.2L6.8 7l-5.6 5.8" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" fill="none" />
  </Svg>
);
export const RefreshIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="refreshRounded" size={size} color={color} />;
