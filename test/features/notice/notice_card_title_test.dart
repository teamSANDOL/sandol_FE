import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/notice/domain/model/notice.dart';
import 'package:handori/features/notice/presentation/widget/notice_card.dart';

Notice _n(String title, String author) => Notice(
  id: 1,
  url: 'u',
  title: title,
  author: author,
  createdAt: '2026-11-01T00:00:00',
);

void main() {
  test('배지와 같은 [부서] 접두는 제목에서 뗀다', () {
    expect(titleWithoutAuthor(_n('[도서관] 휴관 안내', '도서관')), '휴관 안내');
  });

  test('다른 부서 접두나 제목 전체가 접두뿐이면 그대로 둔다', () {
    expect(titleWithoutAuthor(_n('[학사] 안내', '도서관')), '[학사] 안내');
    expect(titleWithoutAuthor(_n('[도서관]', '도서관')), '[도서관]');
  });
}
