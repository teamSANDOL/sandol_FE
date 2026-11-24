import { StyleSheet, View } from 'react-native';
import { Chevron, HandolCard, HPressable, HText, Icon, colors, metrics, spacing } from '@/design-system';
import { copyText, dial } from '../contactActions';
import { usePinnedOrganizationUnits } from '../hooks';
import { formatPhone, type OrganizationUnit } from '../model';

/** 시안에서 번호 열이 시작하는 위치 */
const NAME_WIDTH = 138;

/**
 * 홈 '학과/부서 조회' 카드 (Figma 2153:352). 계약: props 를 바꾸지 말 것.
 * 자주 찾는 부서 연락처를 바로 걸 수 있게 두고, 아래 줄로 전체 조직도에 들어간다.
 * 조직도를 못 불러오면 연락처 없이 진입 줄만 남는다.
 */
export function OrganizationQuickCard({ onOpenAll }: { onOpenAll: () => void }) {
  const units = usePinnedOrganizationUnits();
  return (
    <HandolCard>
      {units.length > 0 && (
        <>
          {/* 줄마다 위아래 8씩 터치 여백이 있어 시안의 12 / 16 여백에서 뺀다. */}
          <View style={{ height: spacing.xs }} />
          {units.map((u) => (
            <ContactRow key={u.name} unit={u} />
          ))}
          <View style={{ height: spacing.sm }} />
          <View style={styles.divider} />
        </>
      )}
      <HPressable accessibilityRole="button" onPress={onOpenAll} style={styles.openAll}>
        <View style={{ flex: 1 }}>
          <HText variant="headline">전체학과/ 부서 조회</HText>
          <View style={{ height: 3 }} />
          <HText variant="caption" tone="muted">
            전체 조직도와 연락처를 확인하세요
          </HText>
        </View>
        <Chevron />
      </HPressable>
    </HandolCard>
  );
}

/** 부서명 · 번호 · 전화 아이콘 한 줄. 누르면 전화, 길게 누르면 번호 복사. */
function ContactRow({ unit }: { unit: OrganizationUnit }) {
  const phone = unit.phone ?? '';
  return (
    <HPressable
      accessibilityRole="button"
      accessibilityLabel={`${unit.name} 전화 걸기`}
      onPress={() => dial(phone)}
      onLongPress={() => copyText(formatPhone(phone), '전화번호')}
      style={styles.contactRow}
    >
      <View style={{ width: NAME_WIDTH }}>
        <HText variant="body" weight="bold" numberOfLines={1}>
          {unit.name}
        </HText>
      </View>
      <View style={{ flex: 1 }}>
        <HText variant="caption">{formatPhone(phone)}</HText>
      </View>
      <Icon name="call" accessibilityLabel="전화 걸기" />
    </HPressable>
  );
}

const styles = StyleSheet.create({
  contactRow: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: metrics.cardInset, paddingVertical: spacing.sm },
  divider: { height: 0.5, backgroundColor: colors.border },
  openAll: { flexDirection: 'row', alignItems: 'center', paddingLeft: metrics.cardInset, paddingRight: metrics.cardInset, paddingTop: 13, paddingBottom: 12 },
});
