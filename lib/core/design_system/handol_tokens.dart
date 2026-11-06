import 'package:flutter/material.dart';
import 'package:handori/core/constants/app_colors.dart';
import 'package:handori/core/constants/app_radius.dart';

/// Figma 화면 배경·카드 그라데이션.
///
/// 시안의 배경 그라데이션은 맨 위 색의 투명도가 0이고 흰색 위에 겹쳐 있다
/// (CFE4FA 0% → E8F0FD 35% @72% → E7E5FE 83% @100%). 불투명 색으로 그대로
/// 옮기면 위쪽이 시안보다 훨씬 파랗게 나와서, 흰색 위에 합성한 값을 쓴다.
abstract final class HandolGradients {
  /// 학식 · 공지사항 화면 배경 (위 → 아래)
  static const screen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFE), Color(0xFFEBE9FE)],
    stops: [0, 0.7212, 1],
  );

  /// 셔틀버스 화면 배경. 시안은 흰색 → 8B7CF6을 20%로 깔고 끝점이 화면
  /// 높이의 2.34배라, 화면 아래끝에서 보라가 약 8.5%만 섞인다.
  static const shuttle = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFEFEFE), Color(0xFFF3F2FC)],
  );

  /// 홈 주요일정 카드 (Frame 2147234779, 345x142). 오른쪽 아래의 진한 파랑에서
  /// 왼쪽 위의 밝은 파랑으로 번진다. 시안 변환 행렬에서 구한 시작·끝점이다.
  static const primaryCard = LinearGradient(
    begin: Alignment(0.4029, 2.4699),
    end: Alignment(-1.1724, -1.4264),
    colors: [HandolColors.primary, Color(0xFF5FA8EA)],
  );
}

/// Figma 2142:2334 / 2143:2498 / 2143:2581 / 2143:2624의 공통 토큰.
/// 새 디자인으로 전환하는 화면은 이 토큰을 사용한다.
abstract final class HandolColors {
  static const primary = Color(0xFF3882D3);
  static const background = Color(0xFFFDFDFD);
  static const text = Color(0xFF040404);
  static const muted = Color(0x80040404);
  static const field = Color(0x333882D3);

  /// 카드 · 입력 필드 공용 테두리
  static const border = Color(0xFFD5DAE5);
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

abstract final class HandolTypography {
  static const titleAccent = TextStyle(color: HandolColors.primary);
  static const captionLink = TextStyle(
    color: HandolColors.link,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.underline,
  );
  static const caption = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 16 / 14,
    letterSpacing: -0.55,
    color: HandolColors.text,
  );
  static const body = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 18 / 16,
    letterSpacing: -0.55,
    color: HandolColors.text,
  );
  static const headline = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 22 / 20,
    letterSpacing: -0.55,
    color: HandolColors.text,
  );
  static const title = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 24 / 22,
    letterSpacing: -0.55,
    color: HandolColors.text,
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
extension HandolTextStyleX on TextStyle {
  TextStyle get strong => copyWith(fontWeight: FontWeight.w700);
  TextStyle get muted => copyWith(color: HandolColors.muted);
  TextStyle get accent => copyWith(color: HandolColors.primary);
  TextStyle get onPrimary => copyWith(color: HandolColors.background);
  TextStyle get inactive => copyWith(color: HandolColors.inactive);
}

/// 카드 그림자. primary 10%, blur 4 (Figma DROP_SHADOW).
abstract final class HandolShadows {
  static const card = [
    BoxShadow(color: Color(0x1A3882D3), blurRadius: 4, offset: Offset(0, 4)),
  ];
}

abstract final class HandolSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 40.0;
}

abstract final class HandolMetrics {
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

abstract final class HandolTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Pretendard',
    scaffoldBackgroundColor: HandolColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: HandolColors.primary).copyWith(
      primary: HandolColors.primary,
      surface: HandolColors.background,
      onSurface: HandolColors.text,
      error: HandolColors.error,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: HandolColors.primary,
      selectionColor: HandolColors.field,
      selectionHandleColor: HandolColors.primary,
    ),
  );
}
