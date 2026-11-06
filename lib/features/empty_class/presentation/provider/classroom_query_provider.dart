import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/empty_class/domain/model/classroom_query.dart';

part 'classroom_query_provider.g.dart';

/// 홈 카드와 상세 지도가 함께 보는 조회 구간.
/// keepAlive 라 앱이 살아 있는 동안 사용자가 고른 구간과 축 기준 시각을 유지한다.
@Riverpod(keepAlive: true)
class ClassroomQueryController extends _$ClassroomQueryController {
  @override
  ClassroomQuery build() => ClassroomQuery.defaultFor(KoreaTime.now());

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

  /// 날짜를 바꾼다. 고른 구간이 새 축 안에 들어가면 그대로 두고(교시 선택 유지),
  /// 아니면 그날의 기본 구간으로 맞춘다.
  void setDay(int daysAhead) {
    if (daysAhead == state.daysAhead) return;
    final next = ClassroomQuery.forDay(KoreaTime.now(), daysAhead);
    final fits =
        state.startMinutes >= next.anchorMinutes &&
        state.endMinutes <= ClassroomQuery.hardEnd;
    state = fits
        ? next.copyWith(
            startMinutes: state.startMinutes,
            endMinutes: state.endMinutes,
          )
        : next;
  }

  void resetToNow() => state = ClassroomQuery.defaultFor(KoreaTime.now());

  /// 화면에 들어올 때 한 번 호출. 앵커가 10분 이상 오래됐을 때만 축을 다시
  /// 맞추므로 홈을 오갈 때마다 API 를 다시 부르지 않는다.
  void syncToNow() {
    final now = KoreaTime.now();
    // 자정을 넘겨 '오늘'이 바뀌었으면 처음부터 다시 맞춘다.
    final baseWeekday = (state.weekday - 1 - state.daysAhead) % 7 + 1;
    if (baseWeekday != now.weekday) {
      state = ClassroomQuery.defaultFor(now);
      return;
    }
    // 다른 날의 축은 고정이라 맞출 게 없다.
    if (!state.isToday) return;
    final anchor = ClassroomQuery.minutesOf(now);
    if (anchor - state.anchorMinutes < ClassroomQuery.staleAfter) return;
    if (!ClassroomQuery.todaySelectable(now)) {
      state = ClassroomQuery.defaultFor(now); // 오늘 칸이 끝나면 내일로
      return;
    }

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
