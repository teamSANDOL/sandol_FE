import { useEffect, useRef } from 'react';
import { ActivityIndicator, Animated, Keyboard, ScrollView, StyleSheet, TextInput, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { HPressable, HText, HandolCard, colors, radius, spacing, typography } from '@/design-system';
import { MaterialIcon, type MaterialIconName } from '@/features/empty_class/components/MaterialIcon';
import type { SearchResult } from '../search';
import { MapColors } from '../theme';
import { MapButton } from './MapCommon';

/** 시트 손잡이 (2451:1122 Vector 5, 42x8) */
export function Grip() {
  return <View style={styles.grip} />;
}

/** 지도 왼쪽 원형 버튼 (46x46, 2451:1122 Frame 2147235235/6) */
export function RoundButton({ label, icon, color = colors.text, onPress }: { label: string; icon: MaterialIconName; color?: string; onPress: () => void }) {
  return (
    <View style={styles.round}>
      <HPressable accessibilityRole="button" accessibilityLabel={label} borderless onPress={onPress} style={styles.roundInner}>
        <MaterialIcon name={icon} size={22} color={color} />
      </HPressable>
    </View>
  );
}

/** 시트가 거의 전체로 올라왔을 때 지도를 덮는 어두운 막 + '지도' 라벨 (2158:1177) */
export function MapCover({ visible, onPress }: { visible: boolean; onPress: () => void }) {
  const insets = useSafeAreaInsets();
  const opacity = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    Animated.timing(opacity, { toValue: visible ? 1 : 0, duration: 200, useNativeDriver: true }).start();
  }, [visible, opacity]);
  return (
    <Animated.View pointerEvents={visible ? 'auto' : 'none'} style={[StyleSheet.absoluteFill, { opacity }]}>
      <HPressable accessibilityRole="button" accessibilityLabel="지도 보기" onPress={onPress} rippleColor="transparent" style={styles.cover}>
        <View style={[styles.coverDark, { paddingTop: insets.top + 12 }]}>
          <HText variant="title" tone="onPrimary">
            지도
          </HText>
          <View style={{ height: 7 }} />
          <Grip />
        </View>
      </HPressable>
    </Animated.View>
  );
}

interface TopBarProps {
  isTuk: boolean;
  results: SearchResult[];
  search: string;
  onSearch: (q: string) => void;
  focused: boolean;
  onFocusChange: (f: boolean) => void;
  onTab: (tuk: boolean) => void;
  onPick: (r: SearchResult) => void;
}

/**
 * 장소 검색창 + 교내시설/TUK 월드 탭 (2451:1122 상단). 검색어가 있으면 건물 · TUK 월드 업체 중
 * 이름이 맞는 곳을 아래에 띄운다.
 */
export function MapTopBar({ isTuk, results, search, onSearch, focused, onFocusChange, onTab, onPick }: TopBarProps) {
  const showResults = search.trim().length > 0 && focused;
  return (
    <View>
      <View style={styles.searchBox}>
        <View style={{ width: 48, alignItems: 'center' }}>
          <MaterialIcon name="search" size={24} color={colors.primary} />
        </View>
        <TextInput
          value={search}
          onChangeText={onSearch}
          onFocus={() => onFocusChange(true)}
          onBlur={() => onFocusChange(false)}
          placeholder="장소를 검색하세요"
          placeholderTextColor={colors.muted}
          returnKeyType="search"
          accessibilityLabel="장소 검색"
          style={styles.input}
        />
      </View>
      {showResults ? (
        <View style={{ marginTop: spacing.xs }}>
          <HandolCard>
            <ScrollView style={{ maxHeight: 240 }} keyboardShouldPersistTaps="handled" nestedScrollEnabled>
              {results.length === 0 ? (
                <View style={{ padding: spacing.md }}>
                  <HText variant="caption" tone="muted">
                    검색 결과가 없어요
                  </HText>
                </View>
              ) : (
                results.map((r) => (
                  <HPressable
                    key={`${r.kind}-${r.title}`}
                    accessibilityRole="button"
                    onPress={() => {
                      Keyboard.dismiss();
                      onPick(r);
                    }}
                    style={styles.result}
                  >
                    <HText variant="body">{r.title}</HText>
                    <HText variant="caption" tone="muted">
                      {r.sub}
                    </HText>
                  </HPressable>
                ))
              )}
            </ScrollView>
          </HandolCard>
        </View>
      ) : (
        <>
          <View style={{ height: spacing.sm }} />
          <View style={styles.tabs}>
            <View style={{ flex: 1 }}>
              <MapButton label="교내시설" primary={!isTuk} onPress={() => onTab(false)} />
            </View>
            <View style={{ flex: 1 }}>
              <MapButton label="TUK 월드" primary={isTuk} onPress={() => onTab(true)} />
            </View>
          </View>
        </>
      )}
    </View>
  );
}

/** 빈 강의실을 다시 불러오는 동안의 작은 표시 */
export function RefreshingChip() {
  return (
    <HandolCard padding={0} contentStyle={styles.chip}>
      <ActivityIndicator size="small" color={colors.primary} style={styles.spinner} />
      <View style={{ width: spacing.sm }} />
      <HText variant="caption">빈 강의실 갱신 중</HText>
    </HandolCard>
  );
}

const styles = StyleSheet.create({
  grip: { width: 42, height: 8, borderRadius: 4, backgroundColor: MapColors.line },
  round: {
    width: 46,
    height: 46,
    borderRadius: 23,
    borderWidth: 1,
    borderColor: MapColors.line,
    backgroundColor: colors.background,
    boxShadow: '0px 1px 3px rgba(0,0,0,0.25)',
  },
  roundInner: { width: 44, height: 44, borderRadius: 22, alignItems: 'center', justifyContent: 'center' },
  cover: { flex: 1, backgroundColor: MapColors.coverMain },
  coverDark: { flex: 1, alignItems: 'center', backgroundColor: MapColors.coverDark },
  searchBox: {
    height: 51,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: MapColors.line,
    backgroundColor: colors.background,
  },
  input: { ...typography.caption, flex: 1, height: 51, paddingVertical: 0, paddingRight: 12 },
  // dense ListTile + 부제 = 최소 높이 64
  result: { minHeight: 64, justifyContent: 'center', paddingHorizontal: spacing.md },
  tabs: { flexDirection: 'row', gap: 29 },
  chip: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 12, paddingVertical: 7 },
  spinner: { transform: [{ scale: 0.6 }], width: 12, height: 12 },
});
