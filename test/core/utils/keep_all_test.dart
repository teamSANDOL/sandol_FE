import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/core/utils/keep_all.dart';

const _wj = '⁠';

/// [text]를 폭 [width]에 그려 각 줄의 글자를 돌려준다.
List<String> _lines(WidgetTester tester, String text, double width) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  // 각 줄의 왼쪽 끝 위치가 그 줄의 시작 글자다.
  final starts = [
    for (final m in painter.computeLineMetrics())
      painter
          .getPositionForOffset(Offset(0, m.baseline - m.ascent + m.height / 2))
          .offset,
    text.length,
  ];
  final lines = [
    for (var i = 0; i < starts.length - 1; i++)
      text.substring(starts[i], starts[i + 1]).replaceAll(_wj, ''),
  ];
  final plain = text.replaceAll(_wj, '');
  expect(lines.join(), plain);
  return lines;
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Pretendard');
    for (final w in ['Regular', 'Bold']) {
      final f = File('assets/fonts/Pretendard-$w.otf');
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  });

  test('어절 안 글자 사이에만 WJ를 넣고, 공백·개행 주변에는 넣지 않는다', () {
    expect('제공 홍보'.keepAll, '제$_wj공 홍$_wj보');
    expect('가\n나'.keepAll, '가\n나');
    expect('a'.keepAll, 'a');
    expect(''.keepAll, '');
    expect('제공'.keepAll.keepAll, '제$_wj공');
  });

  test('WJ는 폭 0이라 보이지 않고, 지우면 원문과 같다', () {
    double width(String s) {
      final p = TextPainter(
        text: TextSpan(
          text: s,
          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return p.width;
    }

    expect(width('제공 혜택'.keepAll), width('제공 혜택'));
    expect('제공 혜택'.keepAll.replaceAll(_wj, ''), '제공 혜택');
  });

  testWidgets('어절 경계에서만 줄이 바뀐다', (tester) async {
    // 가장 긴 어절("제공합니다")이 한 줄에 들어가는 폭에서는 어절이 쪼개지지 않는다.
    const text = '제휴 혜택을 제공합니다 홍보 문구';
    for (final w in [90.0, 110.0, 130.0, 200.0]) {
      for (final line in _lines(tester, text.keepAll, w)) {
        // 줄은 원문의 어절을 쪼개지 않는다: 줄을 이어 붙인 어절이 모두 원문 어절
        for (final word in line.trim().split(' ')) {
          expect(text.split(' '), contains(word), reason: '폭 $w: "$line"');
        }
      }
    }
  });

  testWidgets('폭보다 긴 어절은 글자 단위로 끊기고 넘치지 않는다', (tester) async {
    const text = '대한민국한국공학대학교산학협력단';
    final lines = _lines(tester, text.keepAll, 60);
    expect(lines.length, greaterThan(1));

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 60,
            child: Text(
              text.keepAll,
              style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(Text)).width, lessThanOrEqualTo(60));
  });
}
