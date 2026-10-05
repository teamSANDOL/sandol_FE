import 'package:flutter/material.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/core/constants/app_radius.dart';

/// Figma 2142:2334 / 2143:2498 / 2143:2581 / 2143:2624의 공통 토큰.
/// 새 디자인으로 전환하는 화면은 이 토큰을 사용한다.
abstract final class SandolColors {
  static const primary = Color(0xFF3882D3);
  static const background = Color(0xFFFDFDFD);
  static const text = Color(0xFF040404);
  static const muted = Color(0x80040404);
  static const field = Color(0x333882D3);

  /// 카드 · 입력 필드 공용 테두리
  static const border = Color(0x5C214A77);
  static const fieldBorder = border;
  static const link = Color(0xCC3882D3);
  static const error = AppColors.danger;

  /// main40. 선택되지 않은 칩 · 홈 하단 광원
  static const primary40 = Color(0x663882D3);

  /// primary 20%(field)를 배경 위에 합성한 불투명 값. 아래 테두리나
  /// 그림자가 비치면 안 되는 곳(겹치는 원형 버튼, 그림자 있는 카드)에 쓴다.
  static const primarySoft = Color(0xFFD5E4F4);

  /// 슬라이더의 선택되지 않은 트랙
  static const track = Color(0xFFE2E2E2);

  /// 지나간 시각 · 비활성 버튼 (Figma 2156:516)
  static const inactive = Color(0xFFA4ABBD);

  /// 정류장 이름처럼 본문보다 한 단계 약한 진회색 (Figma 2156:483)
  static const textSecondary = Color(0xFF404756);

  /// MAIN RED. 회원탈퇴처럼 되돌릴 수 없는 동작
  static const red = Color(0xFFC9273F);

  /// 꺼진 토글 바탕 (text 20%)
  static const text20 = Color(0x33040404);
}

abstract final class SandolTypography {
  static const titleAccent = TextStyle(color: SandolColors.primary);
  static const captionLink = TextStyle(
    color: SandolColors.link,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.underline,
  );
  static const caption = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 16 / 14,
    letterSpacing: -0.55,
    color: SandolColors.text,
  );
  static const body = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 18 / 16,
    letterSpacing: -0.55,
    color: SandolColors.text,
  );
  static const headline = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 22 / 20,
    letterSpacing: -0.55,
    color: SandolColors.text,
  );
  static const title = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 24 / 22,
    letterSpacing: -0.55,
    color: SandolColors.text,
  );
  static const button = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 27.5 / 20,
    letterSpacing: -0.55,
  );
}

/// 시안은 같은 크기에서 굵기·색만 바꿔 쓴다. `caption.strong.accent`처럼 잇는다.
extension SandolTextStyleX on TextStyle {
  TextStyle get strong => copyWith(fontWeight: FontWeight.w700);
  TextStyle get muted => copyWith(color: SandolColors.muted);
  TextStyle get accent => copyWith(color: SandolColors.primary);
  TextStyle get onPrimary => copyWith(color: SandolColors.background);
  TextStyle get inactive => copyWith(color: SandolColors.inactive);
}

/// 개편 전 홈 카드에 쓰던 그림자를 그대로 이어 쓴다.
abstract final class SandolShadows {
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4)),
  ];
}

abstract final class SandolSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 40.0;
}

abstract final class SandolMetrics {
  static const referenceWidth = 412.0;
  static const contentWidth = 346.0;
  static const pageGutter = 33.0;

  /// 카드 안쪽 좌우 여백
  static const cardInset = 20.0;
  static const radius = AppRadius.all;
  static const radiusTop = AppRadius.top;
  static const radiusBottom = BorderRadius.vertical(bottom: AppRadius.radius);
  static const logoSize = 160.0;
  static const iconSize = 24.0;
  static const buttonHeight = 44.0;
}

abstract final class SandolTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Pretendard',
    scaffoldBackgroundColor: SandolColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: SandolColors.primary).copyWith(
      primary: SandolColors.primary,
      surface: SandolColors.background,
      onSurface: SandolColors.text,
      error: SandolColors.error,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: SandolColors.primary,
      selectionColor: SandolColors.field,
      selectionHandleColor: SandolColors.primary,
    ),
  );
}
