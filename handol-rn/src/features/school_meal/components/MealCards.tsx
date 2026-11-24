import { StyleSheet, View } from 'react-native';
import { HText, HandolIconLabel, Icon, LoadingIndicator, spacing, ErrorRetryView, type IconName } from '@/design-system';
import { useQueryClient } from '@tanstack/react-query';
import { buildRestaurantMenus, cardsFor, MEAL_LABEL, type MealType, type Restaurant } from '../model';
import { useMeals } from '../hooks';
import { UnfoldIcon } from './MealIcons';
import { RestaurantCard } from './RestaurantCard';

const MEAL_ICON: Record<MealType, IconName> = {
  breakfast: 'mealBreakfast',
  brunch: 'mealBreakfast',
  lunch: 'mealLunch',
  dinner: 'mealDinner',
};

/** 끼니 헤더 + 식당 카드들. 식사 목록(날짜별)을 여기서 불러온다. */
export function MealCards({ restaurants, mealType, day }: { restaurants: Restaurant[]; mealType: MealType; day: string }) {
  const meals = useMeals(day);
  const client = useQueryClient();
  if (meals.isPending) {
    return (
      <View style={styles.loading}>
        <LoadingIndicator />
      </View>
    );
  }
  if (meals.isError) {
    return (
      <ErrorRetryView title="식단 정보를 불러올 수 없습니다." onRetry={() => void client.invalidateQueries({ queryKey: ['school_meal', 'meals', day] })} />
    );
  }
  const cards = cardsFor(buildRestaurantMenus(restaurants, meals.data), mealType);
  return (
    <View>
      <View style={styles.header}>
        <View style={styles.titleWrap}>
          <HandolIconLabel
            icon={
              <View style={styles.icon}>
                <Icon name={MEAL_ICON[mealType]} />
              </View>
            }
            label={MEAL_LABEL[mealType]}
            variant="title"
            tone="accent"
          />
          <HText variant="caption" tone="secondary">
            {`식당 ${cards.length}곳`}
          </HText>
        </View>
        {/* ponytail: 서버에 좋아요·인기 데이터가 없어 정렬은 동작하지 않는다(표시만). */}
        <HText variant="caption" weight="bold" tone="secondary">
          인기순
        </HText>
        <UnfoldIcon />
      </View>
      {cards.length === 0 ? (
        <HText variant="caption" tone="muted" keepAll style={styles.empty}>
          등록된 식단이 없어요
        </HText>
      ) : (
        <View style={styles.list}>
          {cards.map(({ menu, slot }) => (
            <RestaurantCard key={`${menu.restaurant.id}-${slot.mealType}`} menu={menu} slot={slot} />
          ))}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  loading: { paddingVertical: 40, alignItems: 'center' },
  header: { flexDirection: 'row', alignItems: 'center', marginBottom: 13 },
  titleWrap: { flex: 1, flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', columnGap: spacing.md },
  icon: { width: 24, height: 24, alignItems: 'center', justifyContent: 'center' },
  empty: { textAlign: 'center', paddingVertical: 60 },
  list: { gap: 20 },
});