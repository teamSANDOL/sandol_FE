import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
