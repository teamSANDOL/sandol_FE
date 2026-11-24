import { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { router } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import { AppTopBar, ErrorRetryView, GradientBackground, HText, LoadingIndicator, colors, metrics, spacing } from '@/design-system';
import { MealCards } from '../components/MealCards';
import { DateStrip, MealTabs } from '../components/MealPickers';
import { useMeals, useRestaurants } from '../hooks';
import { buildRestaurantMenus, defaultMeal, nowMealType, todayIso, weekDays, type MealType } from '../model';

/**
 * 학식 탭 (Figma 학식-2): 요일 스트립(이번 주 월~일) → 끼니 탭(조식·점심·저녁) →
 * 그 끼니를 내는 식당 카드.
 */
export default function MealScreen() {
  const today = todayIso();
  const [day, setDay] = useState(today);
  /** 사용자가 끼니 탭을 직접 고른 값. null 이면 기본 끼니 규칙을 따른다. */
  const [picked, setPicked] = useState<MealType | null>(null);
  const restaurants = useRestaurants();
  const meals = useMeals(day);
  const client = useQueryClient();

  const isToday = day === today;
  const menus = restaurants.data && meals.data ? buildRestaurantMenus(restaurants.data, meals.data) : null;
  const mealType = picked ?? defaultMeal({ isToday, menus });

  return (
    <GradientBackground>
      <AppTopBar
        title="학식"
        titleNode={<HText variant="title">학식</HText>}
        onBack={() => router.navigate('/home')}
        backgroundColor={colors.transparent}
        horizontalPadding={metrics.pageGutter - 10}
      />
      <ScrollView contentContainerStyle={styles.content}>
        <DateStrip
          days={weekDays()}
          selected={day}
          onSelect={(d) => {
            setDay(d);
            setPicked(null); // 날짜를 바꾸면 기본 끼니 규칙을 다시 적용
          }}
        />
        <View style={styles.gap18} />
        <MealTabs selected={mealType} nowType={isToday ? nowMealType() : null} onSelect={setPicked} />
        <View style={styles.gap20} />
        {restaurants.isPending ? (
          <View style={styles.loading}>
            <LoadingIndicator />
          </View>
        ) : restaurants.isError ? (
          <ErrorRetryView
            title="식당 정보를 불러올 수 없습니다."
            onRetry={() => void client.invalidateQueries({ queryKey: ['school_meal', 'restaurants'] })}
          />
        ) : (
          <MealCards restaurants={restaurants.data} mealType={mealType} day={day} />
        )}
      </ScrollView>
    </GradientBackground>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: metrics.pageGutter, paddingTop: spacing.md, paddingBottom: spacing.xl },
  gap18: { height: 18 },
  gap20: { height: 20 },
  loading: { paddingTop: 60, alignItems: 'center' },
});
