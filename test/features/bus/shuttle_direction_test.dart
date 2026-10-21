import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:handori/features/bus/data/data_source/shuttle_schedule_data.dart';
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

const _stops = ShuttleScheduleData.stops;
final _school = _at(_stops['main_campus']!.lat!, _stops['main_campus']!.lng!);
final _station = _at(_stops['jeongwang']!.lat!, _stops['jeongwang']!.lng!);

void main() {
  test('가까운 정류장이 출발지가 된다', () {
    expect(
      NearestShuttleOrigin.fromPosition(
        _school.latitude,
        _school.longitude,
        _stops,
      ),
      ShuttleDirection.schoolToJeongwang,
    );
    expect(
      NearestShuttleOrigin.fromPosition(
        _station.latitude,
        _station.longitude,
        _stops,
      ),
      ShuttleDirection.jeongwangToSchool,
    );
  });

  test('서버 좌표를 따르고, 좌표 없는 정류장은 판정에서 뺀다', () {
    // 서버가 정왕역 정류장을 학교 정문 자리로 옮겼다고 치면 학교에서도 정왕역 출발.
    final moved = {
      ..._stops,
      'jeongwang': ShuttleStop(
        name: '정왕역',
        lat: _school.latitude,
        lng: _school.longitude + 0.0001,
      ),
      'main_campus': const ShuttleStop(name: '한국공학대 정문', lat: 37.0, lng: 126.0),
    };
    expect(
      NearestShuttleOrigin.fromPosition(
        _school.latitude,
        _school.longitude,
        moved,
      ),
      ShuttleDirection.jeongwangToSchool,
    );
    // 정왕역 좌표가 null 이면 정왕역 바로 앞이어도 학교 출발(정왕역 제외).
    final noStation = {..._stops, 'jeongwang': const ShuttleStop(name: '정왕역')};
    expect(
      NearestShuttleOrigin.fromPosition(
        _station.latitude,
        _station.longitude,
        noStation,
      ),
      ShuttleDirection.schoolToJeongwang,
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
