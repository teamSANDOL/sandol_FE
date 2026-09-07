import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/features/empty_class/domain/model/classroom_query.dart';

part 'classroom_query_provider.g.dart';

/// 홈 카드와 상세 지도가 함께 보는 조회 구간.
/// keepAlive 라 앱이 살아 있는 동안 사용자가 고른 구간과 축 기준 시각을 유지한다.
@Riverpod(keepAlive: true)
class ClassroomQueryController extends _$ClassroomQueryController {
  @override
  ClassroomQuery build() => ClassroomQuery.defaultFor(DateTime.now());

  /// 축의 디텐트 인덱스로 구간을 고른다. 같은 값이면 아무것도 하지 않는다.
  void setRangeByTick(int startIndex, int endIndex) {
    final ticks = state.ticks;
    final s = startIndex.clamp(0, ticks.length - 2);
    final e = endIndex.clamp(s + 1, ticks.length - 1);
    setRange(ticks[s], ticks[e]);
  }

  void setRange(int startMinutes, int endMinutes) {
    if (startMinutes >= endMinutes) return;
    if (startMinutes == state.startMinutes && endMinutes == state.endMinutes) {
      return;
    }
    state = state.copyWith(startMinutes: startMinutes, endMinutes: endMinutes);
  }

  void setWeekday(int weekday) {
    if (weekday == state.weekday) return;
    state = state.copyWith(weekday: weekday);
  }

  void resetToNow() => state = ClassroomQuery.defaultFor(DateTime.now());

  /// 화면에 들어올 때 한 번 호출. 앵커가 10분 이상 오래됐을 때만 축을 다시
  /// 맞추므로 홈을 오갈 때마다 API 를 다시 부르지 않는다.
  void syncToNow() {
    final now = DateTime.now();
    if (state.weekday != now.weekday) {
      state = ClassroomQuery.defaultFor(now);
      return;
    }
    final anchor = ClassroomQuery.minutesOf(now);
    if (anchor - state.anchorMinutes < ClassroomQuery.staleAfter) return;

    final ticks = ClassroomQuery.ticksFor(anchor);
    // 시작을 "지금"에 두고 있었다면 새 지금으로 따라오고,
    // 나중 시각을 골라 뒀다면 그 정각을 그대로 유지한다.
    final keepsNow = state.startMinutes == state.anchorMinutes;
    final s = keepsNow
        ? anchor
        : ticks[ClassroomQuery.nearestTickIndex(ticks, state.startMinutes)];
    final e = ticks[ClassroomQuery.nearestTickIndex(ticks, state.endMinutes)];
    if (s >= e) {
      state = ClassroomQuery.defaultFor(now);
      return;
    }
    state = ClassroomQuery(
      weekday: now.weekday,
      anchorMinutes: anchor,
      startMinutes: s,
      endMinutes: e,
    );
  }
}
