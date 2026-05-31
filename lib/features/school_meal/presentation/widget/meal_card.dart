import 'package:flutter/material.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/features/school_meal/presentation/model/restaurant_menu.dart';

const _kPrimary = AppColors.primary;

/// 현재 시간 기준 운영 중이거나 다음 운영 예정인 시간대를 찾는다.
MenuSlot? _findCurrentOrNextSlot(List<MenuSlot> slots) {
  final operated = slots.where((s) => s.isOperated).toList();
  if (operated.isEmpty) return null;

  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;

  MenuSlot? nextSlot;
  for (final slot in operated) {
    final parts = slot.timeRange.split('~');
    if (parts.length != 2) continue;

    final startParts = parts[0].trim().split(':');
    final endParts = parts[1].trim().split(':');
    if (startParts.length != 2 || endParts.length != 2) continue;

    final startMinutes = (int.tryParse(startParts[0]) ?? 0) * 60 +
        (int.tryParse(startParts[1]) ?? 0);
    final endMinutes = (int.tryParse(endParts[0]) ?? 0) * 60 +
        (int.tryParse(endParts[1]) ?? 0);

    if (nowMinutes >= startMinutes && nowMinutes < endMinutes) return slot;
    if (nowMinutes < startMinutes) nextSlot ??= slot;
  }

  return nextSlot ?? operated.last;
}

class HomeMealSection extends StatefulWidget {
  final List<RestaurantMenu> menus;
  final VoidCallback? onTap;

  const HomeMealSection({required this.menus, this.onTap, super.key});

  @override
  State<HomeMealSection> createState() => _HomeMealSectionState();
}

class _HomeMealSectionState extends State<HomeMealSection> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.menus.isEmpty) return const SizedBox.shrink();
    if (_selected >= widget.menus.length) _selected = 0;

    final menu = widget.menus[_selected];
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
            itemCount: widget.menus.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final isSelected = i == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = i),
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
                    widget.menus[i].name,
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
          onTap: widget.onTap,
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
                // 식당명 + 위치 + 가격
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
                    if (menu.location != null) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          menu.location!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
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
