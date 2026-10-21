import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/core/network/static_info_dio_provider.dart';
import 'package:handori/features/bus/data/data_source/remote_shuttle_schedule.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';

/// 운영 응답 형식(static-info `ShuttleTrip`)을 줄인 trip.
Map<String, Object?> _trip(
  String origin,
  String destination,
  String time, {
  String dayType = '평일',
  String? end,
  String? note,
  String? boardingPlace,
}) => {
  'place': '26년 셔틀버스 시간표 (2학기)',
  'route': '정왕역 ↔ 본교',
  'direction': '$origin → $destination',
  'origin': origin,
  'via': <String>[],
  'destination': destination,
  'day_type': dayType,
  'day_note': null,
  'departure_time': time,
  'departure_time_end': end,
  'valid_from': '09-01',
  'valid_to': '12-22',
  'period_note': null,
  'boarding_place': boardingPlace,
  'note': note,
};

String _body(List<Map<String, Object?>> trips) =>
    jsonEncode({'sources': const [], 'trips': trips});

/// 노선1 양방향이 있는 응답. 서버 순서는 정렬돼 있지 않다.
final _route1Body = _body([
  _trip('본교', '정왕역', '10:20'),
  _trip('본교', '정왕역', '10:05'),
  _trip('본교', '정왕역', '17:00', end: '18:00', note: '수시운행 (17:00~18:00)'),
  _trip('정왕역', '본교', '08:40', end: '10:00', note: '수시운행'),
  _trip(
    '정왕역',
    '본교',
    '17:00',
    end: '22:17',
    note: '도착버스 탑승',
    boardingPlace: '파리바게뜨 건너편',
  ),
]);

/// 정해진 응답 하나를 돌려주는 어댑터. [status]가 200이 아니면 서버 오류.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body, {this.status = 200});
  final String body;
  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// 기준 시각 고정: 2026-10-06(화) 18:00.
class _FixedClock extends ShuttleClock {
  @override
  DateTime build() => DateTime.utc(2026, 10, 6, 18);
}

void main() {
  group('RemoteShuttleSchedule.tryParse', () {
    test('trip을 방향·요일별로 묶고 시각순으로 정렬한다', () {
      final s = RemoteShuttleSchedule.tryParse(_route1Body)!;
      expect(s.routes, {ShuttleRoute.route1});

      final down =
          s
              .timetableFor(
                route: ShuttleRoute.route1,
                direction: ShuttleDirection.schoolToJeongwang,
                dayType: ShuttleDayType.weekday,
              )!
              .entries;
      expect(down.map((e) => e.time.label), ['10:05', '10:20', '17:00']);
      expect(down.first.type, ShuttleEntryType.fixed);
      // 종료 시각이 있으면 수시운행 구간.
      expect(down.last.type, ShuttleEntryType.flexible);
      expect(down.last.endTime, const ShuttleTime(18, 0));
    });

    test('비고에 도착버스가 있으면 도착버스 탑승, 승차 위치를 안내한다', () {
      final up =
          RemoteShuttleSchedule.tryParse(_route1Body)!
              .timetableFor(
                route: ShuttleRoute.route1,
                direction: ShuttleDirection.jeongwangToSchool,
                dayType: ShuttleDayType.weekday,
              )!
              .entries;
      expect(up.first.type, ShuttleEntryType.flexible);
      expect(up.last.type, ShuttleEntryType.arrivalBoarding);
      expect(up.last.boardingNote, '파리바게뜨 건너편에서 도착 버스 탑승');
    });

    test('평일 trip만 있으면 토요일·공휴일은 미운행', () {
      final s = RemoteShuttleSchedule.tryParse(_route1Body)!;
      for (final day in [ShuttleDayType.saturday, ShuttleDayType.holiday]) {
        expect(
          s.timetableFor(
            route: ShuttleRoute.route1,
            direction: ShuttleDirection.schoolToJeongwang,
            dayType: day,
          ),
          isNull,
        );
      }
    });

    test('토요일·경유 trip은 제2캠퍼스 노선 요일로 들어간다', () {
      final s =
          RemoteShuttleSchedule.tryParse(
            _body([
              _trip('정왕역', '제2캠퍼스', '08:45', dayType: '토요일'),
              _trip('제2캠퍼스', '정왕역', '16:30', dayType: '토요일'),
            ]),
          )!;
      expect(s.routes, {ShuttleRoute.route2});
      expect(
        s
            .timetableFor(
              route: ShuttleRoute.route2,
              direction: ShuttleDirection.schoolToCampus2,
              dayType: ShuttleDayType.saturday,
            )!
            .entries
            .single
            .time,
        const ShuttleTime(8, 45),
      );
    });

    test('한 방향만 있는 노선은 쓰지 않는다(파싱 누락 의심)', () {
      // 운영 응답처럼 제2캠퍼스 노선이 한 방향으로만 올 때.
      final s =
          RemoteShuttleSchedule.tryParse(
            _route1Body.replaceFirst(
              '"trips":[',
              '"trips":[${jsonEncode(_trip('본교', '제2캠퍼스', '08:55'))},',
            ),
          )!;
      expect(s.routes, {ShuttleRoute.route1});
    });

    test('빈 응답·잘못된 형식은 null', () {
      expect(RemoteShuttleSchedule.tryParse(_body([])), isNull);
      expect(RemoteShuttleSchedule.tryParse('not json'), isNull);
      expect(RemoteShuttleSchedule.tryParse('{"trips": 3}'), isNull);
    });
  });

  group('ShuttleScheduleSource 대체 순서', () {
    Future<ProviderContainer> load(_FakeAdapter adapter) async {
      final dio = Dio(BaseOptions(baseUrl: 'https://prod.example.com'))
        ..httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [
          staticInfoDioProvider.overrideWithValue(dio),
          shuttleClockProvider.overrideWith(_FixedClock.new),
        ],
      );
      addTearDown(container.dispose);
      container.listen(shuttleScheduleSourceProvider, (_, _) {});
      // 캐시 읽기 → 요청 → 캐시 쓰기가 끝날 때까지 이벤트 큐를 비운다.
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return container;
    }

    test('서버 성공: 서버 시간표를 쓰고 캐시에 저장한다', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final c = await load(_FakeAdapter(_route1Body));
      expect(c.read(shuttleScheduleSourceProvider)?.routes, {
        ShuttleRoute.route1,
      });
      expect(
        await const FlutterSecureStorage().read(
          key: ShuttleScheduleSource.cacheKey,
        ),
        _route1Body,
      );
    });

    test('서버 실패: 캐시를 쓴다', () async {
      FlutterSecureStorage.setMockInitialValues({
        ShuttleScheduleSource.cacheKey: _route1Body,
      });
      final c = await load(_FakeAdapter('', status: 503));
      expect(c.read(shuttleScheduleSourceProvider)?.routes, {
        ShuttleRoute.route1,
      });
    });

    test('서버 빈 응답: 캐시를 덮어쓰지 않는다', () async {
      FlutterSecureStorage.setMockInitialValues({
        ShuttleScheduleSource.cacheKey: _route1Body,
      });
      final c = await load(_FakeAdapter(_body([])));
      expect(c.read(shuttleScheduleSourceProvider), isNotNull);
      expect(
        await const FlutterSecureStorage().read(
          key: ShuttleScheduleSource.cacheKey,
        ),
        _route1Body,
      );
    });

    test('서버 실패 + 캐시 없음: 내장 시간표(null)', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final c = await load(_FakeAdapter('', status: 503));
      expect(c.read(shuttleScheduleSourceProvider), isNull);
    });

    test('서버가 도착버스 구간을 빠뜨린 방향만 내장 시간표를 쓴다', () async {
      // 운영 응답 형태: 등교는 22:17 막차 한 줄, 하교는 수시운행 포함.
      FlutterSecureStorage.setMockInitialValues({});
      final c = await load(
        _FakeAdapter(
          _body([
            _trip('정왕역', '본교', '08:40', end: '10:00', note: '수시운행'),
            _trip('정왕역', '본교', '22:17', note: '막차'),
            _trip('본교', '정왕역', '17:00', end: '18:00', note: '수시운행'),
            _trip('본교', '정왕역', '23:59'),
          ]),
        ),
      );
      List<ShuttleEntry> entries(ShuttleDirection d) =>
          c
              .read(
                shuttleTimetableProvider(
                  route: ShuttleRoute.route1,
                  direction: d,
                ),
              )!
              .entries;

      final up = entries(ShuttleDirection.jeongwangToSchool);
      expect(up.last.type, ShuttleEntryType.arrivalBoarding); // 내장
      final down = entries(ShuttleDirection.schoolToJeongwang);
      expect(down.map((e) => e.time.label), ['17:00', '23:59']); // 서버
    });
  });
}
