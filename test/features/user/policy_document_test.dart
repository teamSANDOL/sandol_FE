import 'package:flutter_test/flutter_test.dart';
import 'package:handol/features/user/data/policy_document.dart';

String _item(String marker, String body) =>
    '<div class="flex gap-3"><span>$marker</span><div>$body</div></div>';

void main() {
  test('정책 HTML에서 조항 · 단락 · 번호 항목을 뽑는다', () {
    final html =
        '<main><header><h1>개인정보처리방침</h1><p>소개 한 줄</p></header>'
        '<section><h2>제1조(목적)</h2><p><span>목적 &#x27;본문&#x27;</span></p></section>'
        '<section><h2>제2조(정보)</h2><div>'
        '${_item('1.', '<p>필수 정보</p><p>보충 설명</p>${_item('가.', '<p>세부</p>')}')}'
        '</div></section></main>';

    final policy = parsePolicyHtml(html);

    expect(policy.intro, '소개 한 줄');
    final b = policy.blocks;
    expect(b.map((e) => e.text), [
      '제1조(목적)',
      "목적 '본문'",
      '제2조(정보)',
      '필수 정보',
      '보충 설명',
      '세부',
    ]);
    expect(b[0].isHeading, isTrue);
    expect((b[1].marker, b[1].depth), (null, 0));
    expect((b[3].marker, b[3].depth), ('1.', 1));
    expect((b[4].marker, b[4].depth), (null, 1));
    expect((b[5].marker, b[5].depth), ('가.', 2));
  });

  test('본문이 없으면 FormatException', () {
    expect(() => parsePolicyHtml('<html></html>'), throwsFormatException);
  });
}
