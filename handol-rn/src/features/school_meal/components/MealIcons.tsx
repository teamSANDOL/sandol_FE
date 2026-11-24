import { MaterialIcon, colors } from '@/design-system';

/** Material favorite_rounded (좋아요 자리표시) */
export function HeartIcon({ size = 20, color = colors.inactive }: { size?: number; color?: string }) {
  return <MaterialIcon name="favorite" size={size} color={color} />;
}

/** Material unfold_more_rounded */
export function UnfoldIcon({ size = 16, color = colors.textSecondary }: { size?: number; color?: string }) {
  return <MaterialIcon name="unfoldMore" size={size} color={color} />;
}
