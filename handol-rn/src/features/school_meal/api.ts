import { api, resolveUrl } from '@/core/api/client';
import { env } from '@/core/env';
import type { Meal, MealType, Restaurant, TimeRange } from './model';

/** 서버가 size 를 최대 100 으로 제한한다(초과 시 422). 최대치로 요청하고 전 페이지를 돈다. */
const MAX_PAGE_SIZE = 100;

interface PageDto<T> {
  meta: { total: number };
  data: T[];
}

interface TimeRangeDto {
  start: string;
  end: string;
}

export interface RestaurantDto {
  id: number;
  name: string;
  price?: number | null;
  location?: { building?: string | null } | null;
  breakfast_time?: TimeRangeDto | null;
  brunch_time?: TimeRangeDto | null;
  lunch_time?: TimeRangeDto | null;
  dinner_time?: TimeRangeDto | null;
  image_url?: string | null;
}

export interface MealDto {
  id: number;
  menu: string[];
  meal_type: MealType;
  restaurant_id: number;
  image_url?: string | null;
}

/** 절대 주소가 아니면 학식 서버 기준으로 푼다. 빈 값은 없는 것으로 본다. */
export function resolveMealImageUrl(url: string | null | undefined): string | null {
  if (!url) return null;
  try {
    return resolveUrl(url, env.apiBaseUrl);
  } catch {
    return null;
  }
}

const range = (r: TimeRangeDto | null | undefined): TimeRange | null => (r ? { start: r.start, end: r.end } : null);

export function toRestaurant(d: RestaurantDto): Restaurant {
  return {
    id: d.id,
    name: d.name,
    price: d.price ?? null,
    building: d.location?.building ?? null,
    breakfastTime: range(d.breakfast_time),
    brunchTime: range(d.brunch_time),
    lunchTime: range(d.lunch_time),
    dinnerTime: range(d.dinner_time),
    imageUrl: resolveMealImageUrl(d.image_url),
  };
}

export function toMeal(d: MealDto): Meal {
  return {
    id: d.id,
    menu: d.menu,
    mealType: d.meal_type,
    restaurantId: d.restaurant_id,
    imageUrl: resolveMealImageUrl(d.image_url),
  };
}

async function fetchAll<T>(path: string, query: Record<string, string | number>): Promise<T[]> {
  const items: T[] = [];
  for (let page = 1; ; page++) {
    const res = await api.get<PageDto<T>>(path, { query: { ...query, page, size: MAX_PAGE_SIZE } });
    items.push(...res.data);
    if (res.data.length === 0 || items.length >= res.meta.total) return items;
  }
}

export async function fetchRestaurants(): Promise<Restaurant[]> {
  return (await fetchAll<RestaurantDto>('/meal/restaurants/', {})).map(toRestaurant);
}

/** 제공일 하루치. 서버 날짜 필터가 양 끝 포함이라 start = end = 그날로 보낸다. */
export async function fetchMeals(day: string): Promise<Meal[]> {
  return (await fetchAll<MealDto>('/meal/meals', { start_date: day, end_date: day })).map(toMeal);
}
