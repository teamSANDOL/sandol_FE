import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/empty_class/domain/model/class_period.dart';

void main() {
  test('교시 표는 백엔드 변환표와 같다 (1·9·14교시)', () {
    expect(classPeriods, hasLength(14));
    expect(classPeriods.first, (start: 570, end: 620)); // 09:30~10:20
    expect(classPeriods[8], (start: 1045, end: 1095)); // 17:25~18:15
    expect(classPeriods.last, (start: 1300, end: 1350)); // 21:40~22:30
  });

  test('조회 구간을 교시 문구로 바꾼다', () {
    expect(periodLabelOf(570, 620), '1교시');
    expect(periodLabelOf(1300, 1350), '14교시');
    expect(periodLabelOf(570, 1350), '전체 교시');
    expect(periodLabelOf(600, 720), isNull);
  });
}
