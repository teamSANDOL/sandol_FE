import 'package:flutter/material.dart';

/// 공지사항 화면(Figma 공지사항2)에서만 쓰는 색. 공용 토큰에는 없는 값이다.
abstract final class NoticeColors {
  /// 카드·칩·검색창 테두리
  static const border = Color(0xFFD5DAE5);

  /// 카드 제목 (Figma #6B7385)
  static const title = Color(0xFF6B7385);

  /// 날짜 등 보조 글씨 (Figma #8A92A6)
  static const meta = Color(0xFF8A92A6);

  /// NEW 배지
  static const badgeNew = Color(0xFFFD7267);

  /// 화면 배경: 위에서 아래로 CFE4FA → E8F0FD(35%) → E7E5FE(83%)
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFCFE4FA), Color(0xFFE8F0FD), Color(0xFFE7E5FE)],
    stops: [0, 0.35, 0.83],
  );
}
