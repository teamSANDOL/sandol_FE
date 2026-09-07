import 'package:handori/features/empty_class/domain/model/classroom_query.dart';
import 'package:handori/features/empty_class/model/class_model.dart';

abstract class EmptyClassRepository {
  /// [query] 구간 내내 비어 있는 강의실을 건물별로 돌려준다.
  Future<List<EmptyClass>> fetchEmptyClasses(ClassroomQuery query);
}
