abstract class DateFormatter {
  /// [d]의 연·월·일을 "yyyy-MM-dd" 로. 서버 날짜 파라미터와 공휴일 키가 쓴다.
  /// 시간대 변환은 하지 않으므로 KST 벽시계(KoreaTime.now)를 넘기면 한국 날짜.
  static String isoDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// ISO 8601 문자열 → "yyyy. MM. dd." (예: "2026. 03. 17.") — 공지 시안 표기.
  /// 파싱 실패 시 원본 문자열 반환
  static String dotted(String raw) {
    final plain = format(raw);
    if (plain == raw) return raw;
    return '${plain.replaceAll('.', '. ')}.';
  }

  /// ISO 8601 문자열 → "yyyy.MM.dd" (예: "2026.03.17")
  /// 파싱 실패 시 원본 문자열 반환
  static String format(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final y = dt.year.toString();
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y.$m.$d';
    } catch (_) {
      return raw;
    }
  }
}
