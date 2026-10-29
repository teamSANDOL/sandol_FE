import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

/// 시안 값을 흰색(또는 FDFDFD) 위에 합성한 결과와 맞는지 확인한다.
void main() {
  Color over(Color base, Color top, double alpha) =>
      Color.alphaBlend(top.withValues(alpha: alpha), base);

  test('화면 배경은 투명도 0인 CFE4FA에서 시작해 흰색 위에 합성한 값과 같다', () {
    const g = SandolGradients.screen;
    expect(g.colors.first, const Color(0xFFFFFFFF));
    expect(g.stops, [0, 0.7212, 1]);
    final white = const Color(0xFFFFFFFF);
    final mid = over(white, const Color(0xFFE8F0FD), 0.35);
    final bottom = over(white, const Color(0xFFE7E5FE), 0.828125);
    for (final (a, b) in [(g.colors[1], mid), (g.colors[2], bottom)]) {
      expect((a.r - b.r).abs() * 255, lessThan(1.01));
      expect((a.g - b.g).abs() * 255, lessThan(1.01));
      expect((a.b - b.b).abs() * 255, lessThan(1.01));
    }
  });

  test('홈 카드는 오른쪽 아래의 진한 파랑에서 왼쪽 위로 번진다', () {
    const g = SandolGradients.primaryCard;
    final begin = g.begin as Alignment;
    final end = g.end as Alignment;
    expect(begin.x, greaterThan(end.x));
    expect(begin.y, greaterThan(end.y));
    expect(g.colors.first, SandolColors.primary);
  });
}
