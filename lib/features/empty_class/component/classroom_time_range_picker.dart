import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/core/constants/app_text_styles.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/empty_class/domain/model/classroom_query.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';
import 'package:handori/core/constants/app_radius.dart';

/// 조회 구간 선택기. 홈 카드와 상세 지도의 시간 설정 시트가 같이 쓴다.
///
/// 지금부터 그날 마지막 정각(22:00)까지를 1시간 칸으로 깔고 두 손잡이로
/// 구간을 잡는다. 값은 [classroomQueryControllerProvider] 하나에 저장되므로
/// 어느 화면에서 바꾸든 모두 같은 구간을 본다.
/// 드래그 중 미리보기 구간은 [onPreview] 로 알리고, 놓으면 null 을 보낸다.
class ClassroomTimeRangePicker extends ConsumerStatefulWidget {
  final ValueChanged<ClassroomQuery?>? onPreview;

  const ClassroomTimeRangePicker({super.key, this.onPreview});

  @override
  ConsumerState<ClassroomTimeRangePicker> createState() =>
      _ClassroomTimeRangePickerState();
}

class _ClassroomTimeRangePickerState
    extends ConsumerState<ClassroomTimeRangePicker> {
  /// 드래그 중에는 프로바이더를 건드리지 않고 로컬 값만 움직인다.
  RangeValues? _dragging;

  static const double _thumbRadius = 12.2;
  static const double _trackHeight = 12;

  static String _hourLabel(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}시';

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(classroomQueryControllerProvider);
    final ticks = query.ticks;
    final n = ticks.length;

    final committed = RangeValues(
      ClassroomQuery.nearestTickIndex(ticks, query.startMinutes).toDouble(),
      ClassroomQuery.nearestTickIndex(ticks, query.endMinutes).toDouble(),
    );
    final values = _dragging ?? committed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _thumbRadius * 2,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              // 손잡이가 카드 안쪽 여백에 딱 붙도록 트랙 양끝을 반지름만큼 줄인다.
              padding: const EdgeInsets.symmetric(horizontal: _thumbRadius),
              trackHeight: _trackHeight,
              activeTrackColor: SandolColors.primary,
              inactiveTrackColor: SandolColors.track,
              overlayColor: SandolColors.primary.withValues(alpha: .12),
              rangeThumbShape: const _OutlinedThumbShape(radius: _thumbRadius),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              showValueIndicator: ShowValueIndicator.never,
            ),
            // 정각 디텐트에만 멈춘다.
            child: RangeSlider(
              min: 0,
              max: (n - 1).toDouble(),
              divisions: n - 1,
              values: values,
              onChanged: (v) => _onChanged(v, committed, ticks),
              onChangeEnd: (v) {
                setState(() => _dragging = null);
                widget.onPreview?.call(null);
                ref
                    .read(classroomQueryControllerProvider.notifier)
                    .setRangeByTick(v.start.round(), v.end.round());
              },
            ),
          ),
        ),
        // 축의 양끝: 지금 / 마지막 정각
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('지금', style: SandolTypography.caption),
            Text(_hourLabel(ticks.last), style: SandolTypography.caption),
          ],
        ),
      ],
    );
  }

  void _onChanged(RangeValues v, RangeValues committed, List<int> ticks) {
    // 두 손잡이가 겹치면 구간이 사라지므로 그 이동은 받지 않는다.
    if (v.end - v.start < 1) return;
    final prev = _dragging ?? committed;
    final s = v.start.round(), e = v.end.round();
    if (s != prev.start.round() || e != prev.end.round()) {
      HapticFeedback.selectionClick();
    }
    setState(() => _dragging = v);
    widget.onPreview?.call(
      ref
          .read(classroomQueryControllerProvider)
          .copyWith(startMinutes: ticks[s], endMinutes: ticks[e]),
    );
  }
}

/// 흰 원 + 36% 테두리 손잡이 (Figma 2153:307)
class _OutlinedThumbShape extends RangeSliderThumbShape {
  const _OutlinedThumbShape({required this.radius});

  final double radius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop = false,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb thumb = Thumb.start,
    bool isPressed = false,
  }) {
    context.canvas
      ..drawCircle(center, radius, Paint()..color = SandolColors.background)
      ..drawCircle(
        center,
        radius - 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = SandolColors.border,
      );
  }
}

/// 시간 설정 바텀시트. 상세 지도 헤더의 설정 아이콘에서 연다.
Future<void> showClassroomTimeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.value),
      ),
    ),
    builder: (_) => const _ClassroomTimeSheet(),
  );
}

class _ClassroomTimeSheet extends ConsumerStatefulWidget {
  const _ClassroomTimeSheet();

  @override
  ConsumerState<_ClassroomTimeSheet> createState() =>
      _ClassroomTimeSheetState();
}

class _ClassroomTimeSheetState extends ConsumerState<_ClassroomTimeSheet> {
  ClassroomQuery? _preview;

  @override
  Widget build(BuildContext context) {
    final ClassroomQuery query =
        _preview ?? ref.watch(classroomQueryControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(AppRadius.value),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '시간 설정',
                    style: AppTextStyles.title03.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.value),
                  ),
                  child: Text(
                    '${query.dayShort} ${query.timeLabel}',
                    style: AppTextStyles.caption04.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '이 구간 내내 비어 있는 강의실만 보여줘요.',
              style: AppTextStyles.caption04.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            ClassroomTimeRangePicker(
              onPreview: (q) => setState(() => _preview = q),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
