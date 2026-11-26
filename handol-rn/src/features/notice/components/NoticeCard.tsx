import { StyleSheet, View } from 'react-native';
import { formatDate } from '@/core/utils/dateFormatter';
import { HPressable, HText, HandolCard, colors, spacing } from '@/design-system';
import { titleWithoutAuthor, type Notice } from '../model';
import { noticeColors } from '../theme';
import { BookmarkBorderIcon, BookmarkIcon, ChevronRightIcon } from './NoticeIcons';

/** wide: NEW 는 좌우 여백 11, 부서 배지는 7 (Figma 2:6101) */
function Badge({ label, color, wide = false }: { label: string; color: string; wide?: boolean }) {
  return (
    <View style={[styles.badge, wide && styles.badgeWide, { backgroundColor: color }]}>
      <HText variant="caption" weight="bold" tone="onPrimary" numberOfLines={1}>
        {label}
      </HText>
    </View>
  );
}

/**
 * 공지 한 건 (Figma 공지사항2 > Frame 2147234780): 작성 부서 배지 · NEW · 저장 아이콘 /
 * 제목 / 날짜. 본문 미리보기와 D-day 는 API 에 없어 그리지 않는다.
 */
export function NoticeCard({
  notice,
  isSaved,
  isNew,
  onToggleSaved,
  onPress,
}: {
  notice: Notice;
  isSaved: boolean;
  /** NEW 배지 여부. 기준은 model.isNewNotice 가 정한다. */
  isNew: boolean;
  onToggleSaved: () => void;
  onPress: () => void;
}) {
  return (
    <HandolCard isFlat onPress={onPress} contentStyle={styles.card} accessibilityLabel={notice.title}>
      <View style={styles.top}>
        <View style={styles.badges}>
          <View style={styles.shrink}>
            <Badge label={notice.author} color={colors.primary} />
          </View>
          {isNew && <Badge label="NEW" color={noticeColors.badgeNew} wide />}
        </View>
        <HPressable
          accessibilityRole="button"
          accessibilityLabel={isSaved ? '저장 해제' : '저장'}
          onPress={onToggleSaved}
          borderless
          hitSlop={10}
          style={styles.bookmark}
        >
          {isSaved ? <BookmarkIcon size={20} color={colors.primary} /> : <BookmarkBorderIcon size={20} />}
        </HPressable>
      </View>
      <View style={styles.titleRow}>
        <HText variant="caption" weight="bold" keepAll numberOfLines={2} style={styles.title}>
          {titleWithoutAuthor(notice)}
        </HText>
        <ChevronRightIcon color={noticeColors.meta} />
      </View>
      <HText legacy="caption04" weight="regular" style={styles.date}>
        {`${formatDate(notice.createdAt)}.`}
      </HText>
    </HandolCard>
  );
}

const styles = StyleSheet.create({
  // Figma 2:6101: 안쪽 왼쪽 12 · 위 6 · 오른쪽 13 · 아래 8, 배지 줄 아래 12, 날짜 위 8
  card: { paddingLeft: 12, paddingTop: 6, paddingRight: 13, paddingBottom: 8 },
  top: { flexDirection: 'row', alignItems: 'center', height: 20, marginBottom: 12 },
  badges: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
  shrink: { flexShrink: 1 },
  badge: { paddingHorizontal: 7, paddingVertical: 2, borderRadius: 30 },
  badgeWide: { paddingHorizontal: 11 },
  // 아이콘 20 은 오른쪽 끝에 붙고(글리프 여백 4), 누르는 칸은 hitSlop 으로 넓힌다
  bookmark: { width: 20, height: 20, marginRight: -4, alignItems: 'center', justifyContent: 'center' },
  titleRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 8 },
  title: { flex: 1, color: colors.text, lineHeight: 22, letterSpacing: -1, marginRight: 12 },
  /** 12/16, 자간 -0.55, 굵기 기본 */
  date: { color: noticeColors.meta, letterSpacing: -0.55, lineHeight: 16 },
});
