import { StyleSheet, View } from 'react-native';
import { useQueryClient } from '@tanstack/react-query';
import { HPressable, HText, LoadingIndicator, spacing } from '@/design-system';
import { useMeals, useRestaurants } from '../hooks';
import { buildRestaurantMenus, todayIso } from '../model';
import { HomeMealPager } from './HomeMealPager';

/**
 * 홈 학식 섹션 본문 (Flutter home_screen _buildMealSection + HomeMealSection).
 * 데이터 로딩 · 오류 · 빈 상태까지 스스로 처리한다. 계약: props 를 바꾸지 말 것
 */
export function HomeMealSection({ onPress }: { onPress?: () => void }) {
  const restaurants = useRestaurants();
  const meals = useMeals(todayIso());
  const client = useQueryClient();

  if (restaurants.isPending || meals.isPending) {
    return (
      <View style={styles.loading}>
        <LoadingIndicator />
      </View>
    );
  }
  if (restaurants.isError || meals.isError) {
    return (
      <View style={styles.errorRow}>
        <HText variant="caption" tone="muted" keepAll style={styles.flex}>
          학식 정보를 불러올 수 없습니다.
        </HText>
        <HPressable
          accessibilityRole="button"
          onPress={() => void client.invalidateQueries({ queryKey: ['school_meal'] })}
          style={styles.retry}
        >
          <HText variant="caption" tone="accent">
            다시 시도
          </HText>
        </HPressable>
      </View>
    );
  }
  if (restaurants.data.length === 0) {
    return (
      <HText variant="caption" tone="muted" keepAll style={styles.empty}>
        등록된 식당이 없습니다
      </HText>
    );
  }
  return <HomeMealPager menus={buildRestaurantMenus(restaurants.data, meals.data)} onPress={onPress} />;
}

const styles = StyleSheet.create({
  loading: { height: 120, alignItems: 'center', justifyContent: 'center' },
  errorRow: { flexDirection: 'row', alignItems: 'center' },
  flex: { flex: 1 },
  retry: { paddingHorizontal: 12, paddingVertical: 8 },
  empty: { paddingVertical: spacing.lg },
});
