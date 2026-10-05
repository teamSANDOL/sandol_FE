import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/network/static_info_dio_provider.dart';
import 'package:handori/features/empty_class/data/building_locations.dart';
import 'package:handori/features/empty_class/data/data_source/classroom_api.dart';
import 'package:handori/features/empty_class/data/repository/empty_class_repository_impl.dart';
import 'package:handori/features/empty_class/domain/model/building_sort.dart';
import 'package:handori/features/empty_class/domain/model/nearby_empty_class.dart';
import 'package:handori/features/empty_class/domain/repository/empty_class_repository.dart';
import 'package:handori/features/empty_class/model/class_model.dart';
import 'package:handori/features/empty_class/presentation/provider/building_sort_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/classroom_query_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/user_location_provider.dart';

part 'empty_class_provider.g.dart';

// ── API / Repository ────────────────────────────────────────────────────────

@riverpod
ClassroomApi classroomApi(Ref ref) {
  // baseUrl 이 같은 sandori.kr 이라 static-info Dio 를 그대로 쓴다.
  return ClassroomApi(ref.watch(staticInfoDioProvider));
}

/// 건물 전체 강의실 수를 내부 캐시하므로 keepAlive.
@Riverpod(keepAlive: true)
EmptyClassRepository emptyClassRepository(Ref ref) {
  return EmptyClassRepositoryImpl(ref.watch(classroomApiProvider));
}

// ── 빈 강의실 목록 (조회 구간에 따라 갱신) ───────────────────────────────────

@riverpod
Future<List<EmptyClass>> emptyClasses(Ref ref) {
  final query = ref.watch(classroomQueryControllerProvider);
  return ref.watch(emptyClassRepositoryProvider).fetchEmptyClasses(query);
}

// ── 홈 카드: 정렬 설정에 따라 ───────────────────────────────────────────────

/// 내 위치 정렬은 거리순(위치를 모르면 빈 강의실 많은 순), 내 순서 정렬은
/// 기기에 저장된 순서. 좌표가 없는 건물은 거리순에서 항상 뒤로 간다.
@riverpod
Future<List<NearbyEmptyClass>> nearbyEmptyClasses(Ref ref) async {
  // 두 요청을 먼저 모두 시작한다. 순서대로 await 하면 API 응답이 온 뒤에야
  // 권한 요청·GPS(최대 8초)가 시작돼 첫 카드가 그만큼 늦어진다.
  final classesFuture = ref.watch(emptyClassesProvider.future);
  final positionFuture = ref.watch(userLocationProvider.future);
  final classes = await classesFuture;
  final position = await positionFuture;
  final settings =
      ref.watch(buildingSortControllerProvider).valueOrNull ??
      const BuildingSortSettings();

  final items =
      classes.map((c) {
        double? distance;
        if (position != null && c.hasLocation) {
          distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            c.latitude!,
            c.longitude!,
          );
        }
        return NearbyEmptyClass(building: c, distanceMeters: distance);
      }).toList();

  int byCount(NearbyEmptyClass a, NearbyEmptyClass b) {
    final c = b.building.emptyCount.compareTo(a.building.emptyCount);
    return c != 0
        ? c
        : buildingOrder(
          a.building.className,
        ).compareTo(buildingOrder(b.building.className));
  }

  switch (settings.mode) {
    case BuildingSort.custom:
      items.sort((a, b) {
        final r = settings
            .rankOf(a.building.className)
            .compareTo(settings.rankOf(b.building.className));
        return r != 0 ? r : byCount(a, b);
      });
    case BuildingSort.count:
      items.sort(byCount);
    case BuildingSort.distance:
      items.sort((a, b) {
        final da = a.distanceMeters, db = b.distanceMeters;
        if (da != null && db != null) return da.compareTo(db);
        if (da != null) return -1;
        if (db != null) return 1;
        return byCount(a, b);
      });
  }
  return items;
}
