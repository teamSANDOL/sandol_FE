/// 식사 종류. 서버 enum 값(breakfast/brunch/lunch/dinner)과 1:1 매칭된다.
///
/// 도메인 레이어에 위치시켜 presentation 이 DTO 를 import 하지 않고도
/// 식사 유형을 다룰 수 있도록 한다. (§1 의존성 규칙)
enum MealType {
  breakfast,
  brunch,
  lunch,
  dinner;

  /// UI 표기용 한글 라벨
  String get label => switch (this) {
        MealType.breakfast => '조식',
        MealType.brunch => '브런치',
        MealType.lunch => '중식',
        MealType.dinner => '석식',
      };
}
