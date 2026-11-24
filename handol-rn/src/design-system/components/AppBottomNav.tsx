import { StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors, metrics, radius, spacing } from '../tokens';
import type { IconName } from '../assets';
import { HText } from './HText';
import { Icon } from './Icon';
import { HPressable } from './Pressable';

export type BottomNavItem = {
  key: string;
  label: string;
  icon: IconName;
  /** 없으면 icon 을 primary 로 칠해 선택 상태를 나타낸다 */
  activeIcon?: IconName;
};

/** 항목 순서는 탭 라우트 순서와 같아야 한다 (Figma 2086:23) */
export const BOTTOM_NAV_ITEMS: readonly BottomNavItem[] = [
  { key: 'home', label: '홈', icon: 'navHome', activeIcon: 'navHomeActive' },
  { key: 'meal', label: '학식', icon: 'navMeal' },
  { key: 'bus', label: '셔틀버스', icon: 'navBus' },
  { key: 'notice', label: '공지사항', icon: 'navNotice' },
  { key: 'map', label: '맵', icon: 'navMap' },
];

type Props = {
  currentIndex: number;
  onPress: (index: number) => void;
  items?: readonly BottomNavItem[];
};

/** 아이콘마다 높이가 달라(18.8~24) 이 칸 안에서 가운데 맞춰 라벨 줄을 맞춘다 */
const ICON_BOX = 24;

/** 하단 네비 (AppBottomNav) */
export function AppBottomNav({ currentIndex, onPress, items = BOTTOM_NAV_ITEMS }: Props) {
  const insets = useSafeAreaInsets();
  return (
    <View style={[styles.bar, { paddingBottom: insets.bottom }]}>
      <View style={styles.row}>
        {items.map((item, i) => {
          const isSelected = i === currentIndex;
          const iconName = isSelected && item.activeIcon ? item.activeIcon : item.icon;
          return (
            <HPressable
              key={item.key}
              accessibilityRole="tab"
              accessibilityLabel={item.label}
              accessibilityState={{ selected: isSelected }}
              onPress={() => onPress(i)}
              style={styles.item}
              borderless
            >
              <View style={styles.iconBox}>
                <Icon name={iconName} color={isSelected ? colors.primary : colors.text} />
              </View>
              <View style={{ height: spacing.xs }} />
              <HText
                variant="caption"
                weight={isSelected ? 'bold' : undefined}
                tone={isSelected ? 'accent' : undefined}
                numberOfLines={1}
                adjustsFontSizeToFit
                style={styles.label}
              >
                {item.label}
              </HText>
            </HPressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    backgroundColor: colors.background,
    borderTopLeftRadius: radius.md,
    borderTopRightRadius: radius.md,
  },
  row: { height: metrics.bottomNavHeight, flexDirection: 'row' },
  item: { flex: 1, alignItems: 'center', paddingTop: 13 },
  iconBox: { height: ICON_BOX, alignItems: 'center', justifyContent: 'center' },
  label: { paddingHorizontal: 4 },
});
