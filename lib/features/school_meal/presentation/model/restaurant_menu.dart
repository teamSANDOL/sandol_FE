import 'package:handori/features/school_meal/domain/model/meal.dart';
import 'package:handori/features/school_meal/domain/model/meal_type.dart';
import 'package:handori/features/school_meal/domain/model/restaurant.dart';

/// 한 식당의 한 식사 시간대 (조식/점심/저녁/브런치) — 도메인 모델로부터 파생된
/// presentation 전용 view model. (DTO 미참조, §1 준수)
class MenuSlot {
  final MealType mealType;
  final String label; // 조식 / 브런치 / 점심 / 저녁
  final String timeRange; // "11:00~13:00" — 미운영이면 빈 문자열
  final List<String> menu; // 메뉴 항목
  final int? price;

  const MenuSlot({
    required this.mealType,
    required this.label,
    required this.timeRange,
    required this.menu,
    this.price,
  });

  bool get isOperated => timeRange.isNotEmpty && menu.isNotEmpty;
}

/// 식당 + 시간대별 메뉴 묶음
class RestaurantMenu {
  final Restaurant restaurant;
  final List<MenuSlot> slots;

  const RestaurantMenu({required this.restaurant, required this.slots});

  String get name => restaurant.name;

  /// 위치 표기. API(`location.building`)가 있으면 그대로 쓰고, 없으면 식당명
  /// 기준 하드코딩 폴백을 사용한다.
  String? get location =>
      restaurant.locationLabel ?? _fallbackLocationOf(restaurant.name);
}

/// 식당명 부분 일치 → 위치 폴백 매핑.
/// 서버에 위치 정보가 누락된 식당의 위치를 보완한다.
const _kLocationFallback = <String, String>{
  '가가': 'TIP 1층',
  'E동': 'E동 1층',
  '세미콘': '경기도 시흥시 정왕동 1269-13',
  '미가': '경기도 시흥시 산기대학로 236',
};

String? _fallbackLocationOf(String name) {
  for (final entry in _kLocationFallback.entries) {
    if (name.contains(entry.key)) return entry.value;
  }
  return null;
}

/// 시간 문자열을 "HH:MM" 형태로 정규화한다.
/// 서버가 "HH:MM" 또는 ISO datetime("...THH:MM:SS")을 모두 줄 수 있어 대응한다.
String _normalizeTime(String raw) {
  if (raw.contains('T')) {
    final timePart = raw.split('T').last; // "HH:MM:SS..."
    final hm = timePart.split(':');
    if (hm.length >= 2) return '${hm[0]}:${hm[1]}';
  }
  return raw.trim();
}

String _formatRange(TimeRange? range) {
  if (range == null) return '';
  final start = _normalizeTime(range.start);
  final end = _normalizeTime(range.end);
  if (start.isEmpty || end.isEmpty) return '';
  return '$start~$end';
}

/// 식당 목록과 식사 목록을 결합해 화면용 view model 리스트로 변환한다.
List<RestaurantMenu> buildRestaurantMenus(
  List<Restaurant> restaurants,
  List<Meal> meals,
) {
  // 표시 순서 고정: 조식 → 브런치 → 점심 → 저녁
  const order = [
    MealType.breakfast,
    MealType.brunch,
    MealType.lunch,
    MealType.dinner,
  ];

  return restaurants.map((restaurant) {
    final restaurantMeals =
        meals.where((m) => m.restaurantId == restaurant.id).toList();

    Meal? mealOf(MealType type) {
      for (final m in restaurantMeals) {
        if (m.mealType == type) return m;
      }
      return null;
    }

    TimeRange? timeOf(MealType type) => switch (type) {
          MealType.breakfast => restaurant.breakfastTime,
          MealType.brunch => restaurant.brunchTime,
          MealType.lunch => restaurant.lunchTime,
          MealType.dinner => restaurant.dinnerTime,
        };

    final slots = <MenuSlot>[];
    for (final type in order) {
      final meal = mealOf(type);
      final time = timeOf(type);
      // 브런치는 데이터가 있을 때만 노출 (기본 조/중/석 레이아웃 유지)
      if (type == MealType.brunch && meal == null && time == null) continue;
      slots.add(
        MenuSlot(
          mealType: type,
          label: type.label,
          timeRange: _formatRange(time),
          menu: meal?.menu ?? const [],
          price: restaurant.price,
        ),
      );
    }

    return RestaurantMenu(restaurant: restaurant, slots: slots);
  }).toList();
}
