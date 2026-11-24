import { MaterialIcon, colors } from '@/design-system';

type Props = { size?: number; color?: string };

/** 공지 화면의 Material 아이콘 (Flutter notice_page / notice_card / notice_detail_page 와 같은 변형) */
export const SearchIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="search" size={size} color={color} />;
export const TuneIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="tune" size={size} color={color} />;
export const CloseIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="close" size={size} color={color} />;
export const BookmarkIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="bookmark" size={size} color={color} />;
export const BookmarkBorderIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="bookmarkBorder" size={size} color={color} />;
export const ArrowDropDownIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="arrowDropDown" size={size} color={color} />;
export const RefreshIcon = ({ size, color = colors.text }: Props) => <MaterialIcon name="refreshRounded" size={size} color={color} />;
