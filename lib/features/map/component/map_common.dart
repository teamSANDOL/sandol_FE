import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/utils/external_link.dart';
import 'package:url_launcher/url_launcher.dart';

/// 맵 탭에서만 쓰는 색 (Figma '맵' 2451:1122 계열). 공용 토큰에 없는 값만 둔다.
abstract final class MapColors {
  /// 시트 · 입력창 · 칩 테두리, 시트 손잡이
  static const line = Color(0xFFD5DAE5);

  /// 선택되지 않은 탭 · 보조 버튼 · 비어있는 호실 바탕
  static const soft = Color(0xFFE8F0FC);

  /// 시설 아이콘 타일 바탕
  static const tile = Color(0xFFECF4FD);

  /// 수업예정 호실 바탕 · 점 (2538:17489 범례)
  static const busy = Color(0xFFFFE1E2);
  static const busyDot = Color(0xFFE14045);
}

/// 교내 시설 분류. 시설 바로가기 · 필터 · 건물 시트가 같은 이름과 아이콘을 쓴다.
/// 시안의 아이콘은 Lucide 계열이라 가장 가까운 Material 아이콘으로 대신한다.
enum CampusFacility {
  all('전체', Icons.grid_view_rounded),
  emptyClass('빈 강의실', Icons.meeting_room_outlined),
  restaurant('식당', Icons.restaurant),
  cafe('카페', Icons.local_cafe_outlined),
  printer('프린트', Icons.print_outlined),
  studyRoom('스터디룸', Icons.menu_book_outlined),
  library('도서관', Icons.local_library_outlined),
  store('편의점', Icons.storefront_outlined),
  vending('자판기', Icons.local_drink_outlined),
  lounge('휴게공간', Icons.weekend_outlined),
  etc('기타', Icons.more_horiz_rounded);

  final String label;
  final IconData icon;
  const CampusFacility(this.label, this.icon);
}

/// 둥근 사각 아이콘 타일 + 아래 라벨 (2451:1122 '지금 많이 찾는 시설').
class FacilityTile extends StatelessWidget {
  const FacilityTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.size = 47,
    this.selected = false,
    this.enabled = true,
    this.labelStyle = SandolTypography.caption,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  /// 고른 분류 (TUK 월드 2544:18937): primary 바탕에 흰 아이콘
  final bool selected;

  /// 데이터가 없는 시설은 회색 아이콘 (건물 상세 2548:20479)
  final bool enabled;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        selected
            ? SandolColors.background
            : enabled
            ? SandolColors.primary
            : MapColors.line;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: SandolMetrics.radius,
        child: SizedBox(
          width: size + 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? SandolColors.primary
                          : enabled
                          ? MapColors.tile
                          : SandolColors.background,
                  borderRadius: BorderRadius.circular(size * 12 / 47),
                ),
                child: Icon(icon, size: size / 2, color: iconColor),
              ),
              const SizedBox(height: SandolSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: labelStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 맵 시안의 두 가지 버튼: 주 동작(primary) · 보조 동작(soft).
class MapButton extends StatelessWidget {
  const MapButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? SandolColors.background : SandolColors.text;
    return Material(
      color: primary ? SandolColors.primary : MapColors.soft,
      borderRadius: SandolMetrics.radius,
      child: InkWell(
        borderRadius: SandolMetrics.radius,
        onTap: onTap,
        child: SizedBox(
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: SandolSpacing.xs,
            children: [
              if (icon != null) Icon(icon, size: 14, color: fg),
              Text(label, style: SandolTypography.body.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 섹션 제목 줄 (16px). 시트 안 '학습 공간' · '이용 안내' 등.
class MapSectionTitle extends StatelessWidget {
  const MapSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: SandolSpacing.sm),
    child: Text(text, style: SandolTypography.body),
  );
}

/// 도보 길찾기. 네이버 지도 앱이 있으면 앱으로, 없으면 카카오맵 웹 길찾기로 연다.
Future<void> openDirections(
  BuildContext context, {
  required String name,
  required double latitude,
  required double longitude,
}) async {
  final label = Uri.encodeComponent(name);
  final app = Uri.parse(
    'nmap://route/walk?dlat=$latitude&dlng=$longitude&dname=$label'
    '&appname=kr.sandori.handori',
  );
  try {
    if (await launchUrl(app, mode: LaunchMode.externalApplication)) return;
  } on PlatformException {
    // 앱이 없으면 웹으로 넘어간다.
  }
  if (!context.mounted) return;
  await openExternalLink(
    context,
    'https://map.kakao.com/link/to/$label,$latitude,$longitude',
  );
}
