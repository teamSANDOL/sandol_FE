import { useSyncExternalStore } from 'react';
import { useQuery } from '@tanstack/react-query';
import { fetchMeals, fetchRestaurants } from './api';

export function useRestaurants() {
  return useQuery({ queryKey: ['school_meal', 'restaurants'], queryFn: fetchRestaurants });
}

/** day: "yyyy-MM-dd" (KST 제공일) */
export function useMeals(day: string) {
  return useQuery({ queryKey: ['school_meal', 'meals', day], queryFn: () => fetchMeals(day) });
}

// 홈 식당 칩과 학식 탭이 공유하는 선택 식당(SelectedRestaurantId, keepAlive)
let selectedId: number | null = null;
const listeners = new Set<() => void>();

export function selectRestaurant(id: number | null): void {
  if (id === selectedId) return;
  selectedId = id;
  listeners.forEach((l) => l());
}

export function useSelectedRestaurantId(): number | null {
  return useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    () => selectedId,
  );
}
