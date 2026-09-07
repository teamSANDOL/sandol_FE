import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/core/constants/app_text_styles.dart';
import 'package:handori/features/empty_class/domain/model/classroom_query.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';

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

  static const double _thumbRadius = 10;
  static const double _trackHeight = 10;
  static const double _cellGap = 3;

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
    final s = values.start.round();
    final e = values.end.round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final inner = w - 2 * _thumbRadius;
        double xOf(int i) => _thumbRadius + i / (n - 1) * inner;
        final cellW = inner / (n - 1);
        // 칸이 좁으면 라벨을 한 칸 걸러 찍되, 양끝은 항상 남긴다.
        final labelEvery = cellW < 30 ? 2 : 1;

        return SizedBox(
          height: 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 시간 칸: 선택될 때마다 하나씩 차오른다
              for (var i = 0; i < n - 1; i++)
                Positioned(
                  left: xOf(i) + _cellGap / 2,
                  width: cellW - _cellGap,
                  top: 18 - _trackHeight / 2,
                  height: _trackHeight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: i >= s && i < e
                          ? AppColors.primary
                          : const Color(0xFFE9EEF3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              // 손잡이 (트랙은 투명). 정각 디텐트에만 멈춘다.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 36,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    padding: const EdgeInsets.symmetric(
                        horizontal: _thumbRadius),
                    trackHeight: _trackHeight,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: Colors.white,
                    overlayColor: AppColors.primary.withValues(alpha: .12),
                    rangeThumbShape: const RoundRangeSliderThumbShape(
                      enabledThumbRadius: _thumbRadius,
                      elevation: 2,
                      pressedElevation: 4,
                    ),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 18),
                    rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                    activeTickMarkColor: Colors.transparent,
                    inactiveTickMarkColor: Colors.transparent,
                    showValueIndicator: ShowValueIndicator.never,
                  ),
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
              // 디텐트 라벨: 지금 / 정각
              for (var i = 0; i < n; i++)
                if (i == 0 || i == n - 1 || (n - 1 - i) % labelEvery == 0)
                  Positioned(
                    left: xOf(i) - 18,
                    width: 36,
                    top: 40,
                    child: Text(
                      i == 0 ? '지금' : '${ticks[i] ~/ 60}시',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption04.copyWith(
                        fontSize: 10,
                        color: i >= s && i <= e
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontWeight:
                            i == s || i == e ? FontWeight.w700 : FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
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

/// 시간 설정 바텀시트. 상세 지도 헤더의 설정 아이콘에서 연다.
Future<void> showClassroomTimeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text('시간 설정',
                      style: AppTextStyles.title03
                          .copyWith(color: Colors.black87)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
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
              style: AppTextStyles.caption04.copyWith(color: AppColors.textMuted),
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
