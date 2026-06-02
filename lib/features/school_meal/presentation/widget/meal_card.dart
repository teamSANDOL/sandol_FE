import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/features/school_meal/domain/model/meal_type.dart';
import 'package:handori/features/school_meal/presentation/model/restaurant_menu.dart';
import 'package:handori/features/school_meal/presentation/provider/selected_restaurant_id_notifier.dart';

const _kPrimary = AppColors.primary;

/// 현재 시각이 어느 식사 시간대에 속하는지 기준으로 노출 우선순위를 정한다.
///
/// 식당 운영시간(timeRange)이 등록돼 있지 않은 경우의 폴백 기준이다.
/// 핵심 요구사항: 18시가 지나면 저녁 메뉴를 우선 노출한다.
List<MealType> _preferredMealOrderAt(int nowMinutes) {
  const breakfastEnd = 10 * 60 + 30; // 10:30
  const dinnerStart = 18 * 60; // 18:00
  if (nowMinutes < breakfastEnd) {
    return const [
      MealType.breakfast,
      MealType.brunch,
      MealType.lunch,
      MealType.dinner,
    ];
  }
  if (nowMinutes < dinnerStart) {
    return const [
      MealType.lunch,
      MealType.brunch,
      MealType.breakfast,
      MealType.dinner,
    ];
  }
  return const [
    MealType.dinner,
    MealType.lunch,
    MealType.brunch,
    MealType.breakfast,
  ];
}

/// 현재 시간 기준 운영 중이거나 다음 운영 예정인 시간대를 찾는다.
///
/// 메뉴가 등록돼 있으면 운영시간(timeRange) 미등록 식당(예: 가가식당)도 노출한다.
/// 운영시간이 있는 슬롯은 현재/다음 시간대 우선순위로 고르고, 시간대를 판정할 수
/// 없으면(운영시간 미등록) 현재 시각이 속한 식사 시간대를 우선 노출한다.
/// 예: 18시 이후엔 저녁 메뉴가 있으면 저녁을 보여준다.
MenuSlot? _findCurrentOrNextSlot(List<MenuSlot> slots) {
  final withMenu = slots.where((s) => s.menu.isNotEmpty).toList();
  if (withMenu.isEmpty) return null;

  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;

  MenuSlot? nextSlot;
  for (final slot in withMenu) {
    final parts = slot.timeRange.split('~');
    if (parts.length != 2) continue;

    final startParts = parts[0].trim().split(':');
    final endParts = parts[1].trim().split(':');
    if (startParts.length != 2 || endParts.length != 2) continue;

    final startMinutes = (int.tryParse(startParts[0]) ?? 0) * 60 +
        (int.tryParse(startParts[1]) ?? 0);
    final endMinutes = (int.tryParse(endParts[0]) ?? 0) * 60 +
        (int.tryParse(endParts[1]) ?? 0);

    // 지금 운영 중인 시간대를 최우선 노출한다.
    if (nowMinutes >= startMinutes && nowMinutes < endMinutes) return slot;
    if (nowMinutes < startMinutes) nextSlot ??= slot;
  }

  // 곧 시작하는(다음) 운영 시간대가 있으면 그것을 노출한다.
  if (nextSlot != null) return nextSlot;

  // 운영시간으로 특정하지 못하면 현재 시각이 속한 식사 시간대를 우선 노출한다.
  for (final type in _preferredMealOrderAt(nowMinutes)) {
    for (final slot in withMenu) {
      if (slot.mealType == type) return slot;
    }
  }
  return withMenu.first;
}

class HomeMealSection extends ConsumerWidget {
  final List<RestaurantMenu> menus;
  final VoidCallback? onTap;

  const HomeMealSection({required this.menus, this.onTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (menus.isEmpty) return const SizedBox.shrink();

    // 선택 상태는 전역 provider(식당 ID)로부터 파생한다. 상세 페이지에서 탭을
    // 바꾸면 ID가 갱신되고, 홈으로 돌아왔을 때 같은 칩이 선택돼 보인다.
    final selectedId = ref.watch(selectedRestaurantIdProvider);
    var selected = menus.indexWhere((m) => m.restaurant.id == selectedId);
    if (selected < 0) selected = 0;

    final menu = menus[selected];
    final slot = _findCurrentOrNextSlot(menu.slots);
    final price = slot?.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 식당 선택 칩
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: menus.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final isSelected = i == selected;
              return GestureDetector(
                onTap: () => ref
                    .read(selectedRestaurantIdProvider.notifier)
                    .select(menus[i].restaurant.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? _kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _kPrimary : Colors.grey.shade300,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    menus[i].name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // 선택된 식당 메뉴 카드
        GestureDetector(
          onTap: () {
            // 상세 페이지가 동일한 식당으로 진입하도록 현재 선택 ID를 확정한다.
            ref
                .read(selectedRestaurantIdProvider.notifier)
                .select(menu.restaurant.id);
            onTap?.call();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBorder.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 식당명 + 가격
                Row(
                  children: [
                    Text(
                      menu.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (price != null)
                      Text(
                        '${price ~/ 1000},${(price % 1000).toString().padLeft(3, '0')}원',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0088CC),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // 메뉴 아이템 칩
                if (slot != null && slot.menu.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: slot.menu.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  const Text(
                    '오늘은 운영하지 않아요',
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
