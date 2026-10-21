import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/core/network/static_info_dio_provider.dart';
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/bus/data/data_source/remote_shuttle_schedule.dart';
import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/next_shuttle_calculator.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';

/// 계약(2026-10-22) 예시를 바탕으로 만든 응답. [segments]로 방향별 구간을
/// 바꾸고, 주지 않은 방향은 `segments: []`(운행 없음)다.
String _response({
  String date = '2026-10-22',
  String dayType = 'weekday',
  String version = 'v1',
  bool needsReview = false,
  double? stationLat = 37.3512712,
  Map<String, List<Map<String, Object?>>> segments = const {},
}) {
  Map<String, Object?> dir(String id, String from, String to) => {
    'id': id,
    'from': from,
    'to': to,
    'via': id.endsWith('station') ? ['main_campus'] : <String>[],
    'segments': segments[id] ?? const [],
  };
  return jsonEncode({
    'date': date,
    'day_type': dayType,
    'holiday_name': dayType == 'holiday' ? '임시공휴일' : null,
    'version': version,
    'valid_from': '2026-09-01',
    'valid_to': '2026-12-22',
    'source': {
      'title': '26년 셔틀버스 시간표 (2학기) 9.1 ~ 12.22',
      'pdf_url': 'https://example.com/a.pdf',
      'parsed_at': '2026-10-21T00:00:00+00:00',
      'origin': 'pdf',
      'needs_review': needsReview,
    },
    'stops': [
      {
        'id': 'main_campus',
        'name': '한국공학대 정문',
        'lat': 37.3397375,
        'lng': 126.7322656,
        'boarding_note': '본교 출발은 산융관 앞 정류장',
      },
      {
        'id': 'jeongwang',
        'name': '정왕역',
        'lat': stationLat,
        'lng': stationLat == null ? null : 126.7411157,
        'boarding_note': '정왕역 출발은 꽃집 앞',
      },
      {
        'id': 'campus2',
        'name': '제2캠퍼스',
        'lat': null,
        'lng': null,
        'boarding_note': null,
      },
    ],
    'routes': [
      {
        'id': 'main',
        'name': '정왕역 ↔ 본교',
        'directions': [
          dir('main_out', 'main_campus', 'jeongwang'),
          dir('main_in', 'jeongwang', 'main_campus'),
        ],
      },
      {
        'id': 'campus2',
        'name': '제2캠퍼스 ↔ 본교·정왕역',
        'directions': [
          dir('campus2_out', 'main_campus', 'campus2'),
          dir('campus2_in', 'campus2', 'main_campus'),
          dir('campus2_from_station', 'jeongwang', 'campus2'),
          dir('campus2_to_station', 'campus2', 'jeongwang'),
        ],
      },
    ],
    'notes': ['소요시간 10분'],
  });
}

Map<String, Object?> _fixed(String time, [String? note]) => {
  'type': 'fixed',
  'time': time,
  'note': note,
};

Map<String, Object?> _range(String type, String start, String end) => {
  'type': type,
  'start': start,
  'end': end,
  'note': null,
};

/// 평일 노선1 양방향 + 노선2 두 갈래가 있는 응답.
final _weekday = _response(
  segments: {
    'main_in': [
      _range('frequent', '08:40', '10:00'),
      _fixed('10:00'),
      _range('arrival_board', '17:00', '22:17'),
    ],
    'main_out': [_fixed('10:05'), _fixed('22:40', '막차')],
    'campus2_out': [_fixed('10:00')],
    'campus2_from_station': [_fixed('08:55')],
    'campus2_in': [_fixed('09:40')],
  },
);

/// 요청마다 [handler]로 응답을 정하고 받은 요청을 [requests]에 남기는 어댑터.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final (int, String) Function(RequestOptions) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// KST [kst] 벽시계를 [KoreaTime.clock]에 넣는다(테스트가 끝나면 되돌린다).
void _setKst(DateTime kst) =>
    KoreaTime.clock = () => kst.subtract(KoreaTime.offset);

Future<void> _settle() async {
  // 캐시 읽기 → 요청 → 캐시 쓰기가 끝날 때까지 이벤트 큐를 비운다.
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ShuttleTimetable? _timetable(RemoteShuttleSchedule s, ShuttleDirection d) =>
    s.timetableFor(
      route:
          d == ShuttleDirection.jeongwangToSchool ||
                  d == ShuttleDirection.schoolToJeongwang
              ? ShuttleRoute.route1
              : ShuttleRoute.route2,
      direction: d,
    );

void main() {
  setUp(() => _setKst(DateTime.utc(2026, 10, 22, 10))); // 목요일
  tearDown(() => KoreaTime.clock = DateTime.now);

  group('RemoteShuttleSchedule.tryParse', () {
    test('세 종류 구간을 도메인 항목으로 옮기고 정류장 안내를 붙인다', () {
      final s = RemoteShuttleSchedule.tryParse(_weekday)!;
      expect(s.date, '2026-10-22');
      expect(s.dayType, ShuttleDayType.weekday);
      expect(s.version, 'v1');
      expect(s.needsReview, isFalse);

      final up = _timetable(s, ShuttleDirection.jeongwangToSchool)!.entries;
      expect(up.map((e) => e.type), [
        ShuttleEntryType.flexible,
        ShuttleEntryType.fixed,
        ShuttleEntryType.arrivalBoarding,
      ]);
      expect(up.last.endTime, const ShuttleTime(22, 17));
      expect(up.last.boardingNote, '정왕역 출발은 꽃집 앞');

      final down = _timetable(s, ShuttleDirection.schoolToJeongwang)!.entries;
      expect(down.map((e) => e.time.label), ['10:05', '22:40']);
    });

    test('정왕역 경유편은 같은 쪽 노선2 방향에 시각순으로 묶는다', () {
      final s = RemoteShuttleSchedule.tryParse(_weekday)!;
      expect(
        _timetable(
          s,
          ShuttleDirection.schoolToCampus2,
        )!.entries.map((e) => e.time.label),
        ['08:55', '10:00'],
      );
      expect(
        _timetable(
          s,
          ShuttleDirection.campus2ToSchool,
        )!.entries.map((e) => e.time.label),
        ['09:40'],
      );
    });

    test('빈 방향(segments: [])은 운행 없음', () {
      final s = RemoteShuttleSchedule.tryParse(_response())!;
      final t = _timetable(s, ShuttleDirection.schoolToJeongwang);
      expect(t, isNull);
      expect(
        NextShuttleCalculator.calculate(
          t,
          DateTime.utc(2026, 10, 22, 10),
        ).status,
        ShuttleStatus.notOperating,
      );
    });

    test('정류장 이름·좌표·안내를 읽고 좌표 null 은 그대로 둔다', () {
      final s = RemoteShuttleSchedule.tryParse(_response())!;
      expect(s.stops['main_campus']!.boardingNote, '본교 출발은 산융관 앞 정류장');
      expect(s.stops['campus2']!.lat, isNull);
    });

    test('계약과 다른 형식은 통째로 버린다', () {
      expect(RemoteShuttleSchedule.tryParse('not json'), isNull);
      expect(RemoteShuttleSchedule.tryParse('{"trips": []}'), isNull);
      expect(
        RemoteShuttleSchedule.tryParse(_response(dayType: 'friday')),
        isNull,
      );
      expect(
        RemoteShuttleSchedule.tryParse(
          _response(
            segments: {
              'main_in': [_range('shuttle', '08:40', '10:00')],
            },
          ),
        ),
        isNull,
      );
      // 방향 하나가 빠짐.
      final json = jsonDecode(_weekday) as Map<String, Object?>;
      ((json['routes'] as List).last as Map)['directions'] =
          (((json['routes'] as List).last as Map)['directions'] as List)
              .take(3)
              .toList();
      expect(RemoteShuttleSchedule.tryParse(jsonEncode(json)), isNull);
    });
  });

  group('ShuttleScheduleSource', () {
    late _FakeAdapter adapter;

    Future<ProviderContainer> load(
      (int, String) Function(RequestOptions) h,
    ) async {
      adapter = _FakeAdapter(h);
      final dio = Dio(BaseOptions(baseUrl: 'https://prod.example.com'))
        ..httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [staticInfoDioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);
      container.listen(shuttleScheduleSourceProvider, (_, _) {});
      await _settle();
      return container;
    }

    Future<String?> cache() =>
        const FlutterSecureStorage().read(key: ShuttleScheduleSource.cacheKey);

    test('서버 성공: 오늘 날짜로 받아 쓰고 캐시에 저장한다', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final c = await load((_) => (200, _weekday));
      final req = adapter.requests.single;
      expect(req.queryParameters['date'], '2026-10-22');
      expect(req.headers['If-None-Match'], isNull);
      expect(c.read(shuttleScheduleSourceProvider)?.version, 'v1');
      expect(await cache(), _weekday);
    });

    test('같은 날 캐시: If-None-Match 를 붙이고 304 면 캐시를 쓴다', () async {
      FlutterSecureStorage.setMockInitialValues({
        ShuttleScheduleSource.cacheKey: _weekday,
      });
      final c = await load((_) => (304, ''));
      expect(adapter.requests.single.headers['If-None-Match'], '"v1"');
      expect(c.read(shuttleScheduleSourceProvider)?.version, 'v1');
      expect(await cache(), _weekday);
    });

    test('다른 날 캐시: version 이 같아도 조건 없이 받는다', () async {
      FlutterSecureStorage.setMockInitialValues({
        ShuttleScheduleSource.cacheKey: _response(date: '2026-10-21'),
      });
      final c = await load((_) => (200, _weekday));
      expect(adapter.requests.single.headers['If-None-Match'], isNull);
      expect(c.read(shuttleScheduleSourceProvider)?.date, '2026-10-22');
    });

    test('서버가 공휴일이라 하면 앱 공휴일 목록과 달라도 서버를 따른다', () async {
      // 10/22 는 앱 목록상 평일이지만 서버가 임시공휴일로 확정한 경우.
      FlutterSecureStorage.setMockInitialValues({});
      final c = await load((_) => (200, _response(dayType: 'holiday')));
      expect(
        c.read(shuttleScheduleSourceProvider)?.dayType,
        ShuttleDayType.holiday,
      );
      expect(
        c.read(
          shuttleTimetableProvider(
            route: ShuttleRoute.route1,
            direction: ShuttleDirection.schoolToJeongwang,
          ),
        ),
        isNull,
      );
    });

    test('503: 같은 날 캐시를 쓴다', () async {
      FlutterSecureStorage.setMockInitialValues({
        ShuttleScheduleSource.cacheKey: _weekday,
      });
      final c = await load((_) => (503, '{"detail":"timetable_unavailable"}'));
      expect(c.read(shuttleScheduleSourceProvider)?.version, 'v1');
    });

    test('실패 + 다른 날 캐시: 요일 구분이 같을 때만 쓴다', () async {
      // 10/21(수) 평일 캐시 → 10/22(목) 평일에 쓴다.
      FlutterSecureStorage.setMockInitialValues({
        ShuttleScheduleSource.cacheKey: _response(date: '2026-10-21'),
      });
      var c = await load((_) => (503, ''));
      expect(c.read(shuttleScheduleSourceProvider), isNotNull);

      // 10/24(토) 캐시 → 평일인 오늘엔 쓰지 않고 내장 시간표로.
      FlutterSecureStorage.setMockInitialValues({
        ShuttleScheduleSource.cacheKey: _response(
          date: '2026-10-24',
          dayType: 'saturday',
        ),
      });
      c = await load((_) => (503, ''));
      expect(c.read(shuttleScheduleSourceProvider), isNull);
    });

    test('실패 + 캐시 없음: 내장 시간표', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final c = await load((_) => (500, ''));
      expect(c.read(shuttleScheduleSourceProvider), isNull);
      expect(
        c
            .read(
              shuttleTimetableProvider(
                route: ShuttleRoute.route1,
                direction: ShuttleDirection.jeongwangToSchool,
              ),
            )!
            .entries
            .last
            .type,
        ShuttleEntryType.arrivalBoarding,
      );
    });

    test('형식 불일치 응답은 캐시를 덮어쓰지 않는다', () async {
      FlutterSecureStorage.setMockInitialValues({
        ShuttleScheduleSource.cacheKey: _weekday,
      });
      final c = await load((_) => (200, '{"trips": []}'));
      expect(c.read(shuttleScheduleSourceProvider)?.version, 'v1');
      expect(await cache(), _weekday);
    });

    test('자정을 넘기면 새 날짜로 다시 받는다', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final c = await load(
        (o) => (200, _response(date: o.queryParameters['date'] as String)),
      );
      _setKst(DateTime.utc(2026, 10, 23, 0, 1));
      c.read(shuttleClockProvider.notifier).refresh();
      await _settle();
      expect(adapter.requests.map((r) => r.queryParameters['date']), [
        '2026-10-22',
        '2026-10-23',
      ]);
      expect(c.read(shuttleScheduleSourceProvider)?.date, '2026-10-23');
    });

    test('서버 정류장 좌표가 없으면 내장 대신 판정에서 빠진다', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final c = await load((_) => (200, _response(stationLat: null)));
      final stops = c.read(shuttleStopsProvider);
      expect(stops['jeongwang']!.lat, isNull);
      expect(stops['main_campus']!.name, '한국공학대 정문');
    });
  });
}
