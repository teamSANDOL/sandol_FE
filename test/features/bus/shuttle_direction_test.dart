import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/nearest_shuttle_origin.dart';
import 'package:handori/features/bus/presentation/provider/shuttle_direction_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/user_location_provider.dart';

Position _at(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime.utc(2026, 10, 6),
  accuracy: 1,
  altitude: 0,
  altitudeAccuracy: 1,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

final _school = _at(
  NearestShuttleOrigin.schoolLat,
  NearestShuttleOrigin.schoolLng,
);
final _station = _at(
  NearestShuttleOrigin.stationLat,
  NearestShuttleOrigin.stationLng,
);

void main() {
  test('가까운 정류장이 출발지가 된다', () {
    expect(
      NearestShuttleOrigin.fromPosition(_school.latitude, _school.longitude),
      ShuttleDirection.schoolToJeongwang,
    );
    expect(
      NearestShuttleOrigin.fromPosition(_station.latitude, _station.longitude),
      ShuttleDirection.jeongwangToSchool,
    );
  });

  group('ShuttleDirectionSelection', () {
    ProviderContainer container(Future<Position?> Function() location) {
      final c = ProviderContainer(
        overrides: [userLocationProvider.overrideWith((ref) => location())],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('위치를 못 얻으면 기본값(학교 출발)', () async {
      final c = container(() async => null);
      await c.read(userLocationProvider.future);
      expect(
        c.read(shuttleDirectionSelectionProvider),
        ShuttleDirection.schoolToJeongwang,
      );
    });

    test('정왕역 근처에서 위치가 잡히면 정왕역 출발로 바뀐다', () async {
      final c = container(() async => _station);
      c.listen(shuttleDirectionSelectionProvider, (_, _) {});
      await c.read(userLocationProvider.future);
      expect(
        c.read(shuttleDirectionSelectionProvider),
        ShuttleDirection.jeongwangToSchool,
      );
    });

    test('사용자가 고른 방향은 위치 갱신으로 되돌리지 않는다', () async {
      final c = container(() async => _station);
      c.listen(shuttleDirectionSelectionProvider, (_, _) {});
      c
          .read(shuttleDirectionSelectionProvider.notifier)
          .select(ShuttleDirection.schoolToJeongwang);
      await c.read(userLocationProvider.future);
      expect(
        c.read(shuttleDirectionSelectionProvider),
        ShuttleDirection.schoolToJeongwang,
      );
    });
  });
}
