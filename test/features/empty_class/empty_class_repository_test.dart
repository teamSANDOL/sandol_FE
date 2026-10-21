import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/empty_class/data/data_source/classroom_api.dart';
import 'package:handori/features/empty_class/data/dto/available_classrooms_response.dart';
import 'package:handori/features/empty_class/data/dto/building_classrooms_response.dart';
import 'package:handori/features/empty_class/data/repository/empty_class_repository_impl.dart';
import 'package:handori/features/empty_class/domain/model/classroom_query.dart';

class _FakeApi implements ClassroomApi {
  _FakeApi({this.failRooms = false});

  final bool failRooms;

  @override
  Future<List<BuildingClassroomsResponse>> getClassrooms() async {
    if (failRooms) throw Exception('down');
    return const [
      BuildingClassroomsResponse(
        building: 'E동',
        classrooms: ['E102', 'E101', 'E101'],
      ),
      BuildingClassroomsResponse(building: 'G동', classrooms: ['G301']),
    ];
  }

  @override
  Future<List<AvailableClassroomsResponse>> getAvailableByTime({
    required String day,
    required String startTime,
    required String endTime,
    String? building,
  }) async => const [
    AvailableClassroomsResponse(building: 'E동', emptyClassrooms: ['E101']),
  ];

  @override
  Future<List<AvailableClassroomsResponse>> getAvailableByPeriods({
    required String day,
    required String startPeriod,
    required String endPeriod,
    String? building,
  }) => throw UnimplementedError();
}

void main() {
  const query = ClassroomQuery(
    weekday: 1,
    anchorMinutes: 600,
    startMinutes: 600,
    endMinutes: 720,
  );

  test('전체 강의실 목록을 건물마다 중복 없이 정렬해 담는다', () async {
    final list = await EmptyClassRepositoryImpl(
      _FakeApi(),
    ).fetchEmptyClasses(query);
    final e = list.firstWhere((b) => b.className == 'E동');
    expect(e.classList, ['E101']);
    expect(e.allRooms, ['E101', 'E102']);
    expect(e.totalCount, 2);
    // 빈 강의실이 없는 건물도 0개로 남고 전체 호실은 수업예정으로 쓸 수 있다
    final g = list.firstWhere((b) => b.className == 'G동');
    expect(g.emptyCount, 0);
    expect(g.allRooms, ['G301']);
  });

  test('전체 목록을 못 받으면 빈 호실만 남는다', () async {
    final list = await EmptyClassRepositoryImpl(
      _FakeApi(failRooms: true),
    ).fetchEmptyClasses(query);
    expect(list.single.allRooms, isEmpty);
    expect(list.single.classList, ['E101']);
  });
}
