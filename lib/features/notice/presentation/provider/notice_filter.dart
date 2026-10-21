import 'package:handori/features/notice/domain/model/notice.dart';

/// 공지 화면의 분류 칩. 공지 API 는 분류를 주지 않으므로
/// 학사·장학·비교과·취업·일반은 이미 받아 둔 공지의 작성 부서·제목에
/// 분류 이름이 들어 있는지로 거른다.
enum NoticeFilter {
  all('전체'),
  academic('학사'),
  scholarship('장학'),
  extracurricular('비교과'),
  general('일반'),
  dormitory('생활관'),
  career('취업'),
  saved('저장한 공지'),
  shuttle('셔틀');

  const NoticeFilter(this.label);
  final String label;

  /// 부서·제목 키워드로 거르는 분류인지
  bool get isKeyword => switch (this) {
    academic || scholarship || extracurricular || career || general => true,
    _ => false,
  };

  /// 이 분류가 [notice]를 보여 줄지. 키워드 분류가 아니면 항상 true.
  bool matches(Notice notice) {
    if (!isKeyword) return true;
    final text = '${notice.author} ${notice.title}';
    if (this == general) {
      return !NoticeFilter.values
          .where((f) => f.isKeyword && f != general)
          .any((f) => text.contains(f.label));
    }
    return text.contains(label);
  }
}

/// 분류 [filter]와 검색어 [query](제목·작성 부서)에 맞는 공지만 남긴다.
List<Notice> filterNotices(
  List<Notice> items, {
  required NoticeFilter filter,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  return items
      .where(
        (n) =>
            filter.matches(n) &&
            (q.isEmpty ||
                n.title.toLowerCase().contains(q) ||
                n.author.toLowerCase().contains(q)),
      )
      .toList();
}
