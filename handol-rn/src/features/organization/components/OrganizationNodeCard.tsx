import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Chevron, HandolIconLabel, HPressable, HText, Icon, colors, radius, spacing } from '@/design-system';
import { copyText, dial, openUrl } from '../contactActions';
import { formatPhone, type OrganizationGroup, type OrganizationNode, type OrganizationUnit } from '../model';

/** 하위는 한 단계마다 들여쓰는 폭 */
export const ORG_INDENT = 28;

/**
 * 조직도 노드 한 줄 (Figma 2158:891).
 * 그룹: 폴더 + 이름 + 셰브런(누르면 펼침). 부서: 아바타 + 이름 + 전화 · 링크.
 * 최상위(depth 0) 부서는 '대표연락처'처럼 이름을 강조색 20 굵게 키운다.
 */
export function OrganizationNodeCard({ node, depth = 0 }: { node: OrganizationNode; depth?: number }) {
  return (
    <View style={{ paddingLeft: ORG_INDENT * depth }}>
      {node.kind === 'group' ? <GroupRow node={node} /> : <UnitRow node={node} depth={depth} />}
    </View>
  );
}

function GroupRow({ node }: { node: OrganizationGroup }) {
  const [expanded, setExpanded] = useState(false);
  return (
    <View>
      <View style={styles.clip}>
        <HPressable
          accessibilityRole="button"
          accessibilityState={{ expanded }}
          onPress={() => setExpanded((v) => !v)}
          style={styles.groupRow}
        >
          <View style={{ flex: 1 }}>
            <HandolIconLabel icon={<Icon name="orgFolder" />} label={node.name} variant="body" />
          </View>
          <Chevron direction={expanded ? 'up' : 'down'} />
        </HPressable>
      </View>
      {expanded && node.children.map((child, i) => <OrganizationNodeCard key={`${child.name}-${i}`} node={child} depth={1} />)}
    </View>
  );
}

function UnitRow({ node, depth }: { node: OrganizationUnit; depth: number }) {
  const { phone, url } = node;
  const top = depth === 0;
  return (
    <View style={{ paddingVertical: top ? 0 : 10, gap: top ? spacing.md : spacing.sm }}>
      {top ? (
        <HText variant="headline" weight="bold" tone="accent">
          {node.name}
        </HText>
      ) : (
        <HText variant="body">{node.name}</HText>
      )}
      {(phone || url) && (
        <View style={styles.contactRow}>
          <View style={styles.avatar}>
            <Icon name="orgAvatar" />
          </View>
          <View style={{ flex: 1, gap: spacing.xs }}>
            {phone ? (
              <ContactLine
                icon={<Icon name="orgPhone" />}
                text={formatPhone(phone)}
                onPress={() => dial(phone)}
                onLongPress={() => copyText(formatPhone(phone), '전화번호')}
              />
            ) : null}
            {url ? (
              <ContactLine
                icon={<Icon name="orgMail" />}
                text={url}
                onPress={() => openUrl(url)}
                onLongPress={() => copyText(url, '링크')}
              />
            ) : null}
          </View>
        </View>
      )}
    </View>
  );
}

/** 탭 = 전화/링크, 길게 누름 = 복사 */
function ContactLine({ icon, text, onPress, onLongPress }: { icon: React.ReactNode; text: string; onPress: () => void; onLongPress: () => void }) {
  return (
    <View style={styles.clip}>
      <HPressable accessibilityRole="link" onPress={onPress} onLongPress={onLongPress}>
        <HandolIconLabel
          icon={<View style={styles.smallIcon}>{icon}</View>}
          label={text}
          variant="body"
          gap={14}
        />
      </HPressable>
    </View>
  );
}

const styles = StyleSheet.create({
  clip: { borderRadius: radius.md, overflow: 'hidden' },
  groupRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10 },
  contactRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.lg },
  avatar: { width: 32, height: 32, borderRadius: 16, backgroundColor: colors.primary, alignItems: 'center', justifyContent: 'center' },
  smallIcon: { width: 12, height: 12, alignItems: 'center', justifyContent: 'center' },
});
