import 'package:handori/features/empty_class/data/building_locations.dart';
import 'package:handori/features/empty_class/data/data_source/classroom_api.dart';
import 'package:handori/features/empty_class/domain/model/classroom_query.dart';
import 'package:handori/features/empty_class/domain/repository/empty_class_repository.dart';
import 'package:handori/features/empty_class/model/class_model.dart';

class EmptyClassRepositoryImpl implements EmptyClassRepository {
  final ClassroomApi _api;

  /// 건물별 전체 강의실 수. 학기 단위로만 바뀌므로 인스턴스 수명 동안 캐시.
  Map<String, int>? _totals;

  EmptyClassRepositoryImpl(this._api);

  @override
  Future<List<EmptyClass>> fetchEmptyClasses(ClassroomQuery query) async {
    final results = await Future.wait([
      _api.getAvailableByTime(
        day: query.dayName,
        startTime: query.startTime,
        endTime: query.endTime,
      ),
      _loadTotals(),
    ]);
    final available = results[0] as List;
    final totals = results[1] as Map<String, int>;

    final list = <EmptyClass>[];
    for (final item in available) {
      final rooms = List<String>.from(item.emptyClassrooms)..sort();
      final total = totals[item.building] ?? 0;
      final loc = buildingLocations[item.building];
      list.add(EmptyClass(
        className: item.building,
        classCount: '${rooms.length}',
        trafficIcon: _trafficIcon(rooms.length, total),
        classIcons: buildingIcon(item.building),
        classList: rooms,
        latitude: loc?.latitude,
        longitude: loc?.longitude,
        totalCount: total,
      ));
    }

    // 조회 구간에 빈 강의실이 하나도 없는 건물은 응답에서 빠진다.
    // 전체 목록에 있는 건물이면 0개로 채워 목록에서 사라지지 않게 한다.
    final present = list.map((e) => e.className).toSet();
    for (final entry in totals.entries) {
      if (present.contains(entry.key)) continue;
      final loc = buildingLocations[entry.key];
      list.add(EmptyClass(
        className: entry.key,
        classCount: '0',
        trafficIcon: _trafficIcon(0, entry.value),
        classIcons: buildingIcon(entry.key),
        classList: const [],
        latitude: loc?.latitude,
        longitude: loc?.longitude,
        totalCount: entry.value,
      ));
    }

    list.sort((a, b) =>
        buildingOrder(a.className).compareTo(buildingOrder(b.className)));
    return list;
  }

  Future<Map<String, int>> _loadTotals() async {
    final cached = _totals;
    if (cached != null) return cached;
    try {
      final rows = await _api.getClassrooms();
      return _totals = {
        for (final r in rows) r.building: r.classrooms.toSet().length,
      };
    } catch (_) {
      // 전체 목록 실패는 치명적이지 않다 — 비율 배지만 못 그린다.
      return const {};
    }
  }

  /// 빈 강의실 비율 → 기존 UI 의 신호등 자산 경로.
  /// 절반 이상 비면 여유, 1/4 이상이면 보통, 그 외 혼잡.
  static String _trafficIcon(int empty, int total) {
    if (total <= 0) return 'assets/img/green.png';
    final ratio = empty / total;
    if (ratio >= 0.5) return 'assets/img/green.png';
    if (ratio >= 0.25) return 'assets/img/orange.png';
    return 'assets/img/red.png';
  }
}
