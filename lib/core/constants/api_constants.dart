abstract class ApiConstants {
  static const String baseUrl = 'https://sandori.kr';
  static const String staticInfoBaseUrl = 'https://sandori.kr';

  /// 학식(Meal) 서비스. host:port만 지정하고 경로에 `/meal` 접두사를 포함한다.
  /// (static-info와 동일 규칙 — baseUrl에 path를 넣으면 Dio가 leading `/`를
  ///  절대경로로 처리해 경로가 소실됨)
  static const String mealBaseUrl = 'https://sandori.kr';

  /// 공공데이터포털 경기도(6410000) 버스도착정보 서비스.
  /// host만 지정하고 경로는 API 인터페이스에서 `/busarrivalservice/...`로 작성한다.
  static const String gyeonggiBusBaseUrl = 'https://apis.data.go.kr/6410000';

  static const int defaultPageSize = 10;
}
