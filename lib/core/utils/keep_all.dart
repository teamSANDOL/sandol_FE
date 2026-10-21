/// 한글 문구를 어절(띄어쓰기) 단위로만 줄바꿈하게 하는 확장.
///
/// Flutter는 한글을 글자 단위로 줄바꿈해 "제\n공"처럼 단어 중간이 끊긴다.
/// CSS `word-break: keep-all`처럼, 같은 어절 안의 글자 사이에
/// 줄바꿈 금지 문자 U+2060(WORD JOINER)을 끼워 어절 경계에서만 끊기게 한다.
///
/// - U+2060은 폭 0의 기본 무시(default-ignorable) 문자라 화면에 보이지 않는다.
/// - 한 어절이 줄 폭보다 길면 엔진이 글자 단위로 대신 끊으므로 넘치지 않는다.
/// - 문자열에 실제로 끼워 넣으므로 **표시 직전에만** 쓴다. 검색·비교·저장·복사할
///   원문에는 쓰지 않는다.
const String _wordJoiner = '⁠';

extension KeepAll on String {
  String get keepAll {
    final out = StringBuffer();
    int? prev;
    for (final r in runes) {
      if (prev != null && _joinable(prev) && _joinable(r)) {
        out.write(_wordJoiner);
      }
      out.writeCharCode(r);
      prev = r;
    }
    return out.toString();
  }
}

/// 공백이 아니고, 이모지 결합(ZWJ·변형 선택자)이나 이미 있는 WJ가 아닌 문자
bool _joinable(int r) =>
    r > 0x20 &&
    !(r >= 0x7F && r <= 0xA0) &&
    r != 0x2060 &&
    r != 0x200D &&
    r != 0xFE0F &&
    r != 0x3000 &&
    !(r >= 0x2000 && r <= 0x200B);
