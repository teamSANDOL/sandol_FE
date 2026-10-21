import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

typedef MarkerIcon = ({NOverlayImage icon, NPoint anchor, Size size});

/// 비트맵은 3배로 그려 마커 크기를 논리 크기로 고정한다.
const double _scale = 3;

Future<MarkerIcon> _render(
  double w,
  double h,
  NPoint anchor,
  void Function(Canvas canvas) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w * _scale, h * _scale))
    ..scale(_scale);
  paint(canvas);
  final img = await recorder.endRecording().toImage(
    (w * _scale).round(),
    (h * _scale).round(),
  );
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final icon = await NOverlayImage.fromByteArray(bytes!.buffer.asUint8List());
  return (icon: icon, anchor: anchor, size: Size(w, h));
}

TextPainter _text(String text, TextStyle style) => TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
)..layout();

/// 건물 말풍선: 건물명 + '빈 강의실 N개' 두 줄 카드와 아래 꼬리 (2451:1122 Group 90).
/// 고른 건물은 primary 바탕에 흰 글씨 (2548:19361).
///
/// 시안은 20/16px 글씨지만 A~D동이 붙어 있어 지도에서 겹치므로 한 단계 줄였다.
/// [tipRight]가 true면 꼬리를 말풍선 오른쪽 끝에 붙여 카드가 건물 왼쪽으로
/// 뻗게 한다. 오른쪽 이웃 건물(A동 옆 B동)의 말풍선과 겹치지 않게 하려는 것이다.
Future<MarkerIcon> buildingMarkerIcon(
  String name,
  int emptyCount, {
  required bool selected,
  bool tipRight = false,
}) {
  const padH = 12.0, padV = 8.0, gap = 2.0, tipH = 9.0, tipHalfW = 8.0;
  const shadow = 8.0;
  final fg = selected ? SandolColors.background : SandolColors.text;
  final nameTp = _text(
    name,
    TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: fg,
      height: 1.1,
    ),
  );
  final subTp = _text(
    '빈 강의실 $emptyCount개',
    TextStyle(fontSize: 12, color: fg, height: 1.1),
  );
  final cardW =
      (nameTp.width > subTp.width ? nameTp.width : subTp.width) + padH * 2;
  final cardH = nameTp.height + gap + subTp.height + padV * 2;
  const m = shadow * 2;
  final w = cardW + m * 2, h = cardH + tipH + m * 2;

  // 꼬리는 둥근 모서리(12) 안쪽에 남도록 가장자리에서 20 띄운다.
  final tipX = tipRight ? m + cardW - 20 : m + cardW / 2;

  return _render(w, h, NPoint(tipX / w, (m + cardH + tipH) / h), (canvas) {
    final card = RRect.fromRectAndRadius(
      const Offset(m, m) & Size(cardW, cardH),
      const Radius.circular(12),
    );
    final bubble = Path.combine(
      PathOperation.union,
      Path()..addRRect(card),
      Path()
        ..moveTo(tipX - tipHalfW, m + cardH - 1)
        ..lineTo(tipX + tipHalfW, m + cardH - 1)
        ..lineTo(tipX, m + cardH + tipH)
        ..close(),
    );
    // 시안 그림자: primary 40%, 아래로 9, 블러 20 → 비트맵 여백에 맞춰 줄임
    canvas.drawPath(
      bubble.shift(const Offset(0, 4)),
      Paint()
        ..color = SandolColors.primary.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, shadow / 2),
    );
    canvas.drawPath(
      bubble,
      Paint()
        ..color = selected ? SandolColors.primary : SandolColors.background,
    );
    nameTp.paint(canvas, const Offset(m + padH, m + padV));
    subTp.paint(canvas, Offset(m + padH, m + padV + nameTp.height + gap));
  });
}

/// TUK 월드 업체: primary 둥근 사각 안 흰 분류 아이콘 (2544:18937, 24x24).
Future<MarkerIcon> placeMarkerIcon(IconData icon, {required bool selected}) {
  final side = selected ? 32.0 : 24.0;
  const m = 4.0;
  final glyph = _text(
    String.fromCharCode(icon.codePoint),
    TextStyle(
      fontSize: side / 2,
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      color: SandolColors.background,
    ),
  );
  final w = side + m * 2;
  return _render(w, w, const NPoint(0.5, 0.5), (canvas) {
    final rect = const Offset(m, m) & Size(side, side);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 2)),
        Radius.circular(side / 4),
      ),
      Paint()
        ..color = SandolColors.primary.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(side / 4)),
      Paint()..color = SandolColors.primary,
    );
    glyph.paint(
      canvas,
      rect.center - Offset(glyph.width / 2, glyph.height / 2),
    );
  });
}
