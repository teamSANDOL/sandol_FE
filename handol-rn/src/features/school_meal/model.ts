import { isoDate } from '@/core/utils/dateFormatter';
import { koreaNow, kstParts } from '@/core/utils/koreaTime';

/** 식사 종류. 서버 enum 값(breakfast/brunch/lunch/dinner)과 같다. */
export type MealType = 'breakfast' | 'brunch' | 'lunch' | 'dinner';

export const MEAL_LABEL: Record<MealType, string> = {
  breakfast: '조식',
  brunch: '브런치',
  lunch: '점심',
  dinner: '저녁',
};

/** 학식 탭의 끼니 탭 */
export const MEAL_TABS: readonly MealType[] = ['breakfast', 'lunch', 'dinner'];

/** 표시 순서 고정: 조식 → 브런치 → 점심 → 저녁 */
const MEAL_ORDER: readonly MealType[] = ['breakfast', 'brunch', 'lunch', 'dinner'];

export interface TimeRange {
  start: string;
  end: string;
}

export interface Restaurant {
  id: number;
  name: string;
  price: number | null;
  /** location.building */
  building: string | null;
  breakfastTime: TimeRange | null;
  brunchTime: TimeRange | null;
  lunchTime: TimeRange | null;
  dinnerTime: TimeRange | null;
  imageUrl: string | null;
}

export interface Meal {
  id: number;
  menu: string[];
  mealType: MealType;
  restaurantId: number;
  imageUrl: string | null;
}

/** 한 식당의 한 식사 시간대 (RestaurantMenu 의 MenuSlot) */
export interface MenuSlot {
  mealType: MealType;
  label: string;
  /** "11:00~13:00". 미운영이면 빈 문자열 */
  timeRange: string;
  menu: string[];
  price: number | null;
  imageUrl: string | null;
}

export interface RestaurantMenu {
  restaurant: Restaurant;
  slots: MenuSlot[];
}

const LOCATION_FALLBACK: Readonly<Record<string, string>> = {
  가가: 'TIP 1층',
  E동: 'E동 1층',
  세미콘: '경기도 시흥시 정왕동 1269-13',
  미가: '경기도 시흥시 산기대학로 236',
  다솔: '경기도 시흥시 산기대학로 322',
};

/** 식당명 부분 일치로 앱 사진 에셋을 찾는 열쇠. 사진이 있는 식당만 있다(E동은 아직 없음). */
export type PhotoKey = 'gaga' | 'semicon' | 'miga' | 'dasol';
const PHOTO_KEYS: ReadonlyArray<readonly [string, PhotoKey]> = [
  ['가가', 'gaga'],
  ['세미콘', 'semicon'],
  ['미가', 'miga'],
  ['다솔', 'dasol'],
];

export function photoKeyOf(name: string): PhotoKey | null {
  return PHOTO_KEYS.find(([part]) => name.includes(part))?.[1] ?? null;
}

/** API(location.building)가 있으면 그대로, 없으면 식당명 기준 폴백 */
export function locationOf(menu: RestaurantMenu): string | null {
  if (menu.restaurant.building) return menu.restaurant.building;
  const name = menu.restaurant.name;
  const hit = Object.keys(LOCATION_FALLBACK).find((part) => name.includes(part));
  return hit ? LOCATION_FALLBACK[hit] : null;
}

/** 슬롯(끼니) 사진이 있으면 그것을, 없으면 식당 사진 */
export function photoUrlFor(menu: RestaurantMenu, slot: MenuSlot | null): string | null {
  return slot?.imageUrl ?? menu.restaurant.imageUrl;
}

/** "HH:MM" 또는 ISO datetime("...THH:MM:SS") → "HH:MM" */
export function normalizeTime(raw: string): string {
  if (raw.includes('T')) {
    const hm = (raw.split('T').pop() ?? '').split(':');
    if (hm.length >= 2) return `${hm[0]}:${hm[1]}`;
  }
  return raw.trim();
}

export function formatRange(range: TimeRange | null): string {
  if (!range) return '';
  const start = normalizeTime(range.start);
  const end = normalizeTime(range.end);
  return start && end ? `${start}~${end}` : '';
}

/** 7000 → "7,000원" */
export function formatWon(price: number): string {
  return `${String(price).replace(/\B(?=(\d{3})+$)/g, ',')}원`;
}

function timeOf(r: Restaurant, type: MealType): TimeRange | null {
  switch (type) {
    case 'breakfast':
      return r.breakfastTime;
    case 'brunch':
      return r.brunchTime;
    case 'lunch':
      return r.lunchTime;
    case 'dinner':
      return r.dinnerTime;
  }
}

/** 식당 목록과 식사 목록을 합쳐 화면용 목록으로 (buildRestaurantMenus) */
export function buildRestaurantMenus(restaurants: Restaurant[], meals: Meal[]): RestaurantMenu[] {
  return restaurants.map((restaurant) => {
    const own = meals.filter((m) => m.restaurantId === restaurant.id);
    const slots: MenuSlot[] = [];
    for (const type of MEAL_ORDER) {
      const meal = own.find((m) => m.mealType === type);
      const time = timeOf(restaurant, type);
      // 브런치는 데이터가 있을 때만 노출
      if (type === 'brunch' && !meal && !time) continue;
      slots.push({
        mealType: type,
        label: MEAL_LABEL[type],
        timeRange: formatRange(time),
        menu: meal?.menu ?? [],
        price: restaurant.price,
        imageUrl: meal?.imageUrl ?? null,
      });
    }
    return { restaurant, slots };
  });
}

const BREAKFAST_END = 10 * 60 + 30;
const DINNER_START = 18 * 60;

export function currentMinutes(): number {
  const { hour, minute } = kstParts();
  return hour * 60 + minute;
}

/** 지금(KST) 어느 끼니인지 */
export function nowMealType(nowMinutes: number = currentMinutes()): MealType {
  if (nowMinutes < BREAKFAST_END) return 'breakfast';
  if (nowMinutes < DINNER_START) return 'lunch';
  return 'dinner';
}

function preferredOrder(nowMinutes: number): MealType[] {
  if (nowMinutes < BREAKFAST_END) return ['breakfast', 'brunch', 'lunch', 'dinner'];
  if (nowMinutes < DINNER_START) return ['lunch', 'brunch', 'breakfast', 'dinner'];
  return ['dinner', 'lunch', 'brunch', 'breakfast'];
}

function toMinutes(hm: string): number | null {
  const parts = hm.trim().split(':');
  if (parts.length !== 2) return null;
  return (parseInt(parts[0], 10) || 0) * 60 + (parseInt(parts[1], 10) || 0);
}

/**
 * 운영 중이거나 다음 운영 예정인 끼니. 운영시간으로 못 정하면 현재 시각이 속한
 * 식사 시간대를 우선한다. 홈 카드(요약)와 학식 상세(펼침)가 같은 기준을 쓴다.
 */
export function findCurrentOrNextSlot(slots: MenuSlot[], nowMinutes: number = currentMinutes()): MenuSlot | null {
  const withMenu = slots.filter((s) => s.menu.length > 0);
  if (withMenu.length === 0) return null;

  let next: MenuSlot | null = null;
  for (const slot of withMenu) {
    const parts = slot.timeRange.split('~');
    if (parts.length !== 2) continue;
    const start = toMinutes(parts[0]);
    const end = toMinutes(parts[1]);
    if (start === null || end === null) continue;
    if (nowMinutes >= start && nowMinutes < end) return slot;
    if (nowMinutes < start && !next) next = slot;
  }
  if (next) return next;

  for (const type of preferredOrder(nowMinutes)) {
    const hit = withMenu.find((s) => s.mealType === type);
    if (hit) return hit;
  }
  return withMenu[0];
}

/**
 * 기본 끼니. 오늘이면 지금 끼니부터 뒤로(조식→점심→저녁) 돌며 메뉴 있는 첫 끼니,
 * 아니면 메뉴 있는 첫 끼니. 하나도 없거나 로딩 전이면 지금 끼니.
 */
export function defaultMeal(args: {
  isToday: boolean;
  menus: RestaurantMenu[] | null;
  nowMinutes?: number;
}): MealType {
  const now = nowMealType(args.nowMinutes);
  if (!args.menus) return now;
  const available = new Set<MealType>();
  for (const menu of args.menus) for (const s of menu.slots) if (s.menu.length > 0) available.add(s.mealType);
  const start = args.isToday ? MEAL_TABS.indexOf(now) : 0;
  for (let i = 0; i < MEAL_TABS.length; i++) {
    const type = MEAL_TABS[(start + i) % MEAL_TABS.length];
    if (available.has(type)) return type;
  }
  return now;
}

/** 이 끼니에 메뉴가 등록된 식당 카드 */
export function cardsFor(menus: RestaurantMenu[], mealType: MealType): Array<{ menu: RestaurantMenu; slot: MenuSlot }> {
  const out: Array<{ menu: RestaurantMenu; slot: MenuSlot }> = [];
  for (const menu of menus) {
    for (const slot of menu.slots) {
      if (slot.mealType === mealType && slot.menu.length > 0) out.push({ menu, slot });
    }
  }
  return out;
}

export interface WeekDay {
  /** yyyy-MM-dd */
  iso: string;
  weekday: string;
  month: number;
  day: number;
}

const WEEKDAYS = ['월', '화', '수', '목', '금', '토', '일'] as const;

/** 오늘(KST)이 속한 주의 월~일 */
export function weekDays(today: Date = koreaNow()): WeekDay[] {
  const { year, month, day, weekday } = kstParts(today);
  return WEEKDAYS.map((label, i) => {
    const d = new Date(Date.UTC(year, month - 1, day - (weekday - 1) + i));
    return { iso: isoDate(d), weekday: label, month: d.getUTCMonth() + 1, day: d.getUTCDate() };
  });
}

export function todayIso(): string {
  return isoDate(koreaNow());
}
