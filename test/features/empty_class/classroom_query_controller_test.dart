import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/empty_class/domain/model/classroom_query.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';

void main() {
  test('setRangeByTick 은 디텐트 시각으로 구간을 바꾼다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(classroomQueryControllerProvider.notifier);
    final before = container.read(classroomQueryControllerProvider);
    final ticks = before.ticks;
    if (ticks.length < 3) return; // 심야엔 칸이 하나뿐
    ctrl.setRangeByTick(1, 2);
    final after = container.read(classroomQueryControllerProvider);
    expect(after.startMinutes, ticks[1]);
    expect(after.endMinutes, ticks[2]);
    expect(after.anchorMinutes, before.anchorMinutes); // 축은 그대로
  });

  test('겹치는 인덱스는 최소 한 칸으로 벌린다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(classroomQueryControllerProvider.notifier);
    ctrl.setRangeByTick(0, 0);
    final q = container.read(classroomQueryControllerProvider);
    expect(q.startMinutes, lessThan(q.endMinutes));
    expect(q.endMinutes, q.ticks[1]);
  });

  test('syncToNow 는 10분이 안 지났으면 아무것도 하지 않는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(classroomQueryControllerProvider.notifier);
    final before = container.read(classroomQueryControllerProvider);
    ctrl.syncToNow();
    expect(container.read(classroomQueryControllerProvider), before);
  });

  test('defaultFor 의 시작은 항상 앵커', () {
    final q = ClassroomQuery.defaultFor(DateTime(2026, 9, 7, 9, 5));
    expect(q.startMinutes, q.anchorMinutes);
    expect(q.endMinutes, 11 * 60);
  });

  group('날짜 선택', () {
    // KST 2026-09-07(월) 13:00
    setUp(() => KoreaTime.clock = () => DateTime.utc(2026, 9, 7, 4));
    tearDown(() => KoreaTime.clock = DateTime.now);

    test('다른 날을 고르면 축이 09시부터, 교시 구간은 유지', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(classroomQueryControllerProvider.notifier);
      ctrl.setRange(14 * 60 + 30, 15 * 60 + 20);
      ctrl.setDay(3);
      final q = container.read(classroomQueryControllerProvider);
      expect(q.dayName, '목요일');
      expect(q.anchorMinutes, ClassroomQuery.dayStart);
      expect(q.timeLabel, '14:30 ~ 15:20');
      ctrl.syncToNow(); // 다른 날은 지금에 맞추지 않는다
      expect(container.read(classroomQueryControllerProvider), q);
    });

    test('오늘로 돌아올 때 지난 구간이면 기본값', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(classroomQueryControllerProvider.notifier);
      ctrl.setDay(1);
      ctrl.setDay(0); // 내일 기본 09:00~ 은 오늘 13시 축에 안 들어간다
      final q = container.read(classroomQueryControllerProvider);
      expect(q.isToday, isTrue);
      expect(q.startTime, '13:00');
    });
  });
}
