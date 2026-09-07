import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/empty_class/domain/model/building_sort.dart';
import 'package:handori/features/empty_class/presentation/provider/building_sort_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('정렬 방식과 내 순서는 앱을 다시 켜도(새 컨테이너) 남아 있다', () async {
    final c1 = ProviderContainer();
    await c1.read(buildingSortControllerProvider.future);
    final ctrl = c1.read(buildingSortControllerProvider.notifier);
    await ctrl.setMode(BuildingSort.custom);
    await ctrl.setCustomOrder(['산융', 'E동', 'TIP']);
    c1.dispose();

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final loaded = await c2.read(buildingSortControllerProvider.future);
    expect(loaded.mode, BuildingSort.custom);
    expect(loaded.customOrder, ['산융', 'E동', 'TIP']);
    expect(loaded.rankOf('산융'), 0);
    expect(loaded.rankOf('없는동'), 3);
  });

  test('mergedOrder: 저장된 순서가 앞, 새 건물은 뒤, 사라진 건물은 제외', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(buildingSortControllerProvider.future);
    final ctrl = c.read(buildingSortControllerProvider.notifier);
    await ctrl.setCustomOrder(['산융', '옛건물', 'E동']);
    expect(ctrl.mergedOrder(['A동', 'E동', '산융']), ['산융', 'E동', 'A동']);
  });
}
