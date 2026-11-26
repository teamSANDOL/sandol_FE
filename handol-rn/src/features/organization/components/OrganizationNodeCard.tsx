import { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated, { Easing, useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
import { Chevron, HandolIconLabel, HPressable, HText, Icon, colors, radius, spacing } from '@/design-system';
import { copyText, dial, openUrl } from '../contactActions';
import { formatPhone, type OrganizationGroup, type OrganizationNode, type OrganizationUnit } from '../model';

/** 하위는 한 단계마다 들여쓰는 폭 */
export const ORG_INDENT = 28;

/** 펼침 셰브런 회전 · 하위 목록 크기 (Flutter AnimatedRotation · AnimatedSize 200ms) */
const EXPAND_MS = 200;
const SIZE_TIMING = { duration: EXPAND_MS, easing: Easing.out(Easing.cubic) };
const ROTATE_TIMING = { duration: EXPAND_MS, easing: Easing.linear };

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
  const turn = useSharedValue(0);
  const height = useSharedValue(0);
  useEffect(() => {
    turn.value = withTiming(expanded ? 180 : 0, ROTATE_TIMING);
    if (!expanded) height.value = withTiming(0, SIZE_TIMING);
  }, [expanded, turn, height]);
  const chevronStyle = useAnimatedStyle(() => ({ transform: [{ rotate: `${turn.value}deg` }] }));
  const sizeStyle = useAnimatedStyle(() => ({ height: height.value }));
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
          {/* 시안 2:6017 은 16×9, 에셋은 12×8 */}
          <Animated.View style={chevronStyle}>
            <View style={{ transform: [{ scaleX: 16 / 12 }, { scaleY: 9 / 8 }] }}>
              <Chevron direction="down" color={colors.primary} />
            </View>
          </Animated.View>
        </HPressable>
      </View>
      {/* 접을 때 하위는 바로 빠지고 높이만 줄어든다(AnimatedSize 와 같다) */}
      <Animated.View style={[styles.sizeClip, sizeStyle]}>
        {expanded && (
          <View style={styles.children} onLayout={(e) => (height.value = withTiming(e.nativeEvent.layout.height, SIZE_TIMING))}>
            {node.children.map((child, i) => (
              <OrganizationNodeCard key={`${child.name}-${i}`} node={child} depth={1} />
            ))}
          </View>
        )}
      </Animated.View>
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
                icon={<Icon name="orgPhone" color={colors.primary} />}
                text={formatPhone(phone)}
                onPress={() => dial(phone)}
                onLongPress={() => copyText(formatPhone(phone), '전화번호')}
              />
            ) : null}
            {url ? (
              <ContactLine
                icon={<Icon name="orgMail" color={colors.primary} />}
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
  sizeClip: { overflow: 'hidden' },
  children: { position: 'absolute', top: 0, left: 0, right: 0 },
  groupRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10 },
  contactRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.lg },
  avatar: { width: 32, height: 32, borderRadius: 16, backgroundColor: colors.primary, alignItems: 'center', justifyContent: 'center' },
  smallIcon: { width: 12, height: 12, alignItems: 'center', justifyContent: 'center' },
});
