import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/features/empty_class/domain/model/building_sort.dart';

part 'building_sort_provider.g.dart';

/// 홈 카드 정렬 설정. 기기 로컬에 저장한다.
///
/// 저장소는 프로젝트가 SharedPreferences 대신 쓰는 flutter_secure_storage.
/// 저장이 실패해도 메모리 상태는 유지되므로 화면이 되돌아가지 않는다.
/// 계정 간 동기화가 필요해지면 user service 에 저장 API 를 두고
/// [_load] / [_save] 만 바꾸면 된다.
@Riverpod(keepAlive: true)
class BuildingSortController extends _$BuildingSortController {
  static const _modeKey = 'empty_class.sort_mode';
  static const _orderKey = 'empty_class.custom_order';
  static const _storage = FlutterSecureStorage();

  @override
  Future<BuildingSortSettings> build() => _load();

  Future<BuildingSortSettings> _load() async {
    try {
      final modeName = await _storage.read(key: _modeKey);
      final orderJson = await _storage.read(key: _orderKey);
      final mode = BuildingSort.values.firstWhere(
        (m) => m.name == modeName,
        orElse: () => BuildingSort.distance,
      );
      final order = orderJson == null
          ? const <String>[]
          : (jsonDecode(orderJson) as List).cast<String>();
      return BuildingSortSettings(mode: mode, customOrder: order);
    } catch (_) {
      return const BuildingSortSettings();
    }
  }

  Future<void> _save(BuildingSortSettings s) async {
    try {
      await _storage.write(key: _modeKey, value: s.mode.name);
      await _storage.write(key: _orderKey, value: jsonEncode(s.customOrder));
    } catch (_) {
      // 저장 실패는 조용히 넘긴다. 다음 실행에서 기본값으로 돌아갈 뿐이다.
    }
  }

  BuildingSortSettings get _current =>
      state.valueOrNull ?? const BuildingSortSettings();

  Future<void> setMode(BuildingSort mode) async {
    if (mode == _current.mode) return;
    final next = _current.copyWith(mode: mode);
    state = AsyncData(next);
    await _save(next);
  }

  /// 전체 순서를 교체한다. 시트에서 드래그로 옮길 때 호출.
  Future<void> setCustomOrder(List<String> order) async {
    final next = _current.copyWith(customOrder: List.unmodifiable(order));
    state = AsyncData(next);
    await _save(next);
  }

  /// 저장된 순서에 [all] 의 건물을 합친 목록. 저장된 것이 앞, 새 건물은 뒤.
  List<String> mergedOrder(Iterable<String> all) {
    final saved = _current.customOrder.where(all.contains).toList();
    final rest = all.where((n) => !saved.contains(n)).toList();
    return [...saved, ...rest];
  }
}
