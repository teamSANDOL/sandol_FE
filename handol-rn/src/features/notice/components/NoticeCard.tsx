import { StyleSheet, View } from 'react-native';
import { formatDate } from '@/core/utils/dateFormatter';
import { HPressable, HText, HandolCard, colors, spacing } from '@/design-system';
import { titleWithoutAuthor, type Notice } from '../model';
import { noticeColors } from '../theme';
import { BookmarkBorderIcon, BookmarkIcon } from './NoticeIcons';

function Badge({ label, color }: { label: string; color: string }) {
  return (
    <View style={[styles.badge, { backgroundColor: color }]}>
      <HText variant="caption" tone="onPrimary" numberOfLines={1}>
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
          {isNew && <Badge label="NEW" color={noticeColors.badgeNew} />}
        </View>
        <HPressable
          accessibilityRole="button"
          accessibilityLabel={isSaved ? '저장 해제' : '저장'}
          onPress={onToggleSaved}
          borderless
          style={styles.bookmark}
        >
          {isSaved ? <BookmarkIcon size={20} color={colors.primary} /> : <BookmarkBorderIcon size={20} />}
        </HPressable>
      </View>
      <HText variant="caption" weight="bold" keepAll numberOfLines={2} style={styles.title}>
        {titleWithoutAuthor(notice)}
      </HText>
      <HText legacy="caption04" weight="regular" style={styles.date}>
        {`${formatDate(notice.createdAt)}.`}
      </HText>
    </HandolCard>
  );
}

const styles = StyleSheet.create({
  card: { paddingLeft: 12, paddingTop: 6, paddingRight: 4, paddingBottom: 10, gap: spacing.xs },
  top: { flexDirection: 'row', alignItems: 'center' },
  badges: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
  shrink: { flexShrink: 1 },
  badge: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 30 },
  bookmark: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  title: { color: noticeColors.title, lineHeight: 22, paddingRight: 8 },
  /** Flutter: caption(자간 -0.55).copyWith(fontSize: 12), 굵기 기본 */
  date: { color: noticeColors.meta, letterSpacing: -0.55 },
});
