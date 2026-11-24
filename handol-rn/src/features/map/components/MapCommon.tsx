import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { HPressable, HText, Icon, colors, radius, spacing, type IconName } from '@/design-system';
import { MaterialIcon, type MaterialIconName } from '@/features/empty_class/components/MaterialIcon';
import { MapColors } from '../theme';

export interface TileIcon {
  /** 시안 SVG 아이콘. 있으면 material 대신 시안 크기 그대로 그린다. */
  asset?: IconName;
  material: MaterialIconName;
}

interface TileProps {
  label: string;
  icon: TileIcon;
  onPress: () => void;
  size?: number;
  /** 고른 분류 (TUK 월드 2544:18937): primary 바탕에 흰 아이콘 */
  selected?: boolean;
  /** 데이터가 없는 시설은 흐린 아이콘 (건물 상세 2548:20479) */
  enabled?: boolean;
  labelVariant?: 'caption' | 'headline';
}

/** 둥근 사각 아이콘 타일 + 아래 라벨 (2451:1122 '지금 많이 찾는 시설') */
export function FacilityTile({ label, icon, onPress, size = 47, selected = false, enabled = true, labelVariant = 'caption' }: TileProps) {
  const iconColor = selected ? colors.background : enabled ? colors.primary : MapColors.line;
  const bg = selected ? colors.primary : enabled ? MapColors.tile : colors.background;
  return (
    <View style={[styles.tileClip, { width: size + 8 }]}>
      <HPressable accessibilityRole="button" accessibilityState={{ selected }} accessibilityLabel={label} onPress={onPress} style={styles.tile}>
        <View style={[styles.tileBox, { width: size, height: size, borderRadius: (size * 12) / 47, backgroundColor: bg }]}>
          {icon.asset ? (
            <View style={{ opacity: enabled ? 1 : MapColors.disabledOpacity }}>
              <Icon name={icon.asset} />
            </View>
          ) : (
            <MaterialIcon name={icon.material} size={size / 2} color={iconColor} />
          )}
        </View>
        <View style={{ height: spacing.sm }} />
        {/* 글꼴이 커져도 옆 타일 라벨과 겹치지 않게 타일 폭 안에서 줄인다. */}
        <HText variant={labelVariant} numberOfLines={1} adjustsFontSizeToFit minimumFontScale={0.7}>
          {label}
        </HText>
      </HPressable>
    </View>
  );
}

/** 타일 한 줄. 폭이 넉넉하면 시안대로 양끝 정렬, 좁으면 칸마다 같은 몫으로 줄인다. */
export function TileRow({ children }: { children: ReactNode }) {
  return <View style={styles.tileRow}>{children}</View>;
}

/** 맵 시안의 두 가지 버튼: 주 동작(primary) · 보조 동작(soft) */
export function MapButton({ label, onPress, primary = true, icon }: { label: string; onPress: () => void; primary?: boolean; icon?: MaterialIconName }) {
  const fg = primary ? colors.background : colors.text;
  return (
    <View style={styles.buttonClip}>
      <HPressable
        accessibilityRole="button"
        onPress={onPress}
        style={[styles.button, { backgroundColor: primary ? colors.primary : MapColors.soft }]}
      >
        {icon ? <MaterialIcon name={icon} size={10} color={fg} /> : null}
        <HText variant="body" style={{ color: fg }}>
          {label}
        </HText>
      </HPressable>
    </View>
  );
}

/** 섹션 제목 줄 (16px). 시트 안 '학습 공간' · '이용 안내' 등 */
export function MapSectionTitle({ text }: { text: string }) {
  return (
    <HText variant="body" weight="bold" style={{ paddingBottom: spacing.sm }}>
      {text}
    </HText>
  );
}

const styles = StyleSheet.create({
  tileClip: { borderRadius: radius.md, overflow: 'hidden', flexShrink: 1 },
  tile: { alignItems: 'center' },
  tileBox: { alignItems: 'center', justifyContent: 'center' },
  tileRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' },
  buttonClip: { borderRadius: radius.md, overflow: 'hidden' },
  button: { minHeight: 38, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: spacing.xs },
});
