import {
  buildRestaurantMenus,
  cardsFor,
  defaultMeal,
  findCurrentOrNextSlot,
  formatRange,
  formatWon,
  locationOf,
  nowMealType,
  weekDays,
  type Meal,
  type Restaurant,
} from '../model';

const base: Restaurant = {
  id: 1, name: 'TIP 가가식당', price: 7000, building: null,
  breakfastTime: null, brunchTime: null,
  lunchTime: { start: '11:00', end: '13:00' }, dinnerTime: { start: '2026-01-01T17:00:00', end: '19:00' },
  imageUrl: null,
};
const meal = (type: Meal['mealType'], menu: string[], restaurantId = 1): Meal => ({ id: 1, menu, mealType: type, restaurantId, imageUrl: null });
const min = (h: number, m = 0) => h * 60 + m;

describe('school_meal model', () => {
  it('formats won and time ranges', () => {
    expect(formatWon(7000)).toBe('7,000원');
    expect(formatWon(500)).toBe('500원');
    expect(formatRange(base.dinnerTime)).toBe('17:00~19:00');
    expect(formatRange(null)).toBe('');
  });

  it('builds slots in fixed order and hides empty brunch', () => {
    const [menu] = buildRestaurantMenus([base], [meal('lunch', ['밥'])]);
    expect(menu.slots.map((s) => s.mealType)).toEqual(['breakfast', 'lunch', 'dinner']);
    expect(menu.slots[1].menu).toEqual(['밥']);
  });

  it('picks the slot being served, then the next one', () => {
    const [menu] = buildRestaurantMenus([base], [meal('lunch', ['점심']), meal('dinner', ['저녁'])]);
    expect(findCurrentOrNextSlot(menu.slots, min(12))?.mealType).toBe('lunch');
    expect(findCurrentOrNextSlot(menu.slots, min(14))?.mealType).toBe('dinner');
    expect(findCurrentOrNextSlot(menu.slots, min(20))?.mealType).toBe('dinner');
  });

  it('falls back to the meal period when no hours are registered', () => {
    const noHours: Restaurant = { ...base, lunchTime: null, dinnerTime: null };
    const [menu] = buildRestaurantMenus([noHours], [meal('lunch', ['점심']), meal('dinner', ['저녁'])]);
    expect(findCurrentOrNextSlot(menu.slots, min(19))?.mealType).toBe('dinner');
    expect(findCurrentOrNextSlot(menu.slots, min(9))?.mealType).toBe('lunch');
    expect(findCurrentOrNextSlot([], min(9))).toBeNull();
  });

  it('classifies the current meal by time', () => {
    expect(nowMealType(min(10, 29))).toBe('breakfast');
    expect(nowMealType(min(10, 30))).toBe('lunch');
    expect(nowMealType(min(18))).toBe('dinner');
  });

  it('chooses the default meal tab', () => {
    const menus = buildRestaurantMenus([base], [meal('lunch', ['점심'])]);
    expect(defaultMeal({ isToday: true, menus, nowMinutes: min(19) })).toBe('lunch');
    expect(defaultMeal({ isToday: false, menus, nowMinutes: min(19) })).toBe('lunch');
    expect(defaultMeal({ isToday: true, menus: null, nowMinutes: min(19) })).toBe('dinner');
    expect(defaultMeal({ isToday: true, menus: buildRestaurantMenus([base], []), nowMinutes: min(9) })).toBe('breakfast');
  });

  it('lists only restaurants serving the meal', () => {
    const other: Restaurant = { ...base, id: 2, name: 'E동 레스토랑' };
    const menus = buildRestaurantMenus([base, other], [meal('lunch', ['a']), meal('dinner', ['b'], 2)]);
    expect(cardsFor(menus, 'lunch').map((c) => c.menu.restaurant.id)).toEqual([1]);
  });

  it('falls back to a location by name', () => {
    expect(locationOf(buildRestaurantMenus([base], [])[0])).toBe('TIP 1층');
    expect(locationOf(buildRestaurantMenus([{ ...base, building: 'E동' }], [])[0])).toBe('E동');
  });

  it('lists Monday to Sunday of the week', () => {
    // 2026-11-24 (화, KST 벽시계 = UTC 필드)
    const days = weekDays(new Date(Date.UTC(2026, 10, 24, 12)));
    expect(days.map((d) => d.iso)).toEqual([
      '2026-11-23', '2026-11-24', '2026-11-25', '2026-11-26', '2026-11-27', '2026-11-28', '2026-11-29',
    ]);
    expect(days[0].weekday).toBe('월');
  });
});
