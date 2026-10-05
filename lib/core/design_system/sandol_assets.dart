/// 원본 노드별 Figma export. 같은 로봇이어도 시안의 표정/크롭을 구분한다.
abstract final class SandolAssets {
  static const _base = 'assets/design_system/auth';
  static const welcomeLogo = '$_base/welcome_logo.png'; // 2142:2366
  static const loginLogo = '$_base/login_logo.png'; // 2143:2553
  static const signupMascot = '$_base/signup_mascot.png'; // 2143:2686
  static const kakao = '$_base/kakao.png'; // 2143:2412
  static const google = '$_base/google.png'; // 2143:2490
  static const apple = '$_base/apple.png'; // 2195:509
  static const backArrow = '$_base/back_arrow.svg'; // 2080:191
  static const selectArrow = '$_base/select_arrow.svg'; // 2143:2648
  static const dividerLeft = '$_base/divider_left.svg'; // 2142:2400
  static const dividerRight = '$_base/divider_right.svg'; // 2142:2402
  // VIDEO fill(2219:447)의 정지 프레임. 원본 MP4 확보 후 영상으로 교체한다.
  static const splashPoster = '$_base/splash_art.png';

  // ── 홈(2153:219) ─────────────────────────────────────────────
  static const _home = 'assets/design_system/home';
  static const logo = '$_home/logo.svg'; // 2153:385
  static const user = '$_home/user.svg'; // 2083:26
  static const close = '$_home/close.svg'; // 2158:706
  static const star = '$_home/star.svg'; // 2156:657
  static const starMuted = '$_home/star_muted.svg'; // 2270:508

  // 잠자는 산돌이(2270:510 외 4개 레이어). 겹쳐 그리는 위치는
  // ScheduleSection의 _SleepingMascot에 있다.
  static const mascotBase = '$_home/mascot_base.svg'; // 2270:510
  static const mascotMouth = '$_home/mascot_mouth.svg'; // 2270:520
  static const mascotEyes = '$_home/mascot_eyes.svg'; // 2270:521
  static const mascotZ1 = '$_home/mascot_z1.svg'; // 2270:524
  static const mascotZ2 = '$_home/mascot_z2.svg'; // 2270:525
  // 두 셰브런은 왼쪽을 향한다. 시안처럼 180° 돌려 쓴다.
  static const chevron = '$_home/chevron.svg'; // 2153:382
  static const chevronMuted = '$_home/chevron_muted.svg'; // 2156:439
  static const arrowLeft = '$_home/arrow_left.svg'; // 2153:257
  static const swap = '$_home/swap.svg'; // 2153:260
  static const refresh = '$_home/refresh.svg'; // 2153:262
  static const clock = '$_home/clock.svg'; // 2153:268
  static const busStop = '$_home/bus_stop.svg'; // 2153:273
  static const busDeparture = '$_home/bus_departure.svg'; // 2153:279
  static const info = '$_home/info.svg'; // 2153:295
  static const call = '$_home/call.svg'; // 2153:362
  static const mealGaga = '$_home/meal_gaga.png'; // 2153:238
  // 아래 셋은 시안에 없고 사용자가 직접 넣은 식당 사진
  static const mealDasol = '$_home/meal_dasol.png';
  static const mealMiga = '$_home/meal_miga.png';
  static const mealSemicon = '$_home/meal_semicon.png';

  // ── 셔틀버스(2156:451) ──────────────────────────────────────
  static const _bus = 'assets/design_system/bus';
  static const busStopPin = '$_bus/pin.svg'; // 2156:478
  static const busStopFlag = '$_bus/flag.svg'; // 2156:485
  // 아래 넷은 원형 배경이 SVG 안에 들어 있다.
  static const busPinButton = '$_bus/pin_button.svg'; // 2162:1411
  static const busChevronButton = '$_bus/chevron_button.svg'; // 2162:1413
  static const busSwap = '$_bus/swap.svg'; // 2156:474
  static const busRefresh = '$_bus/refresh.svg'; // 2156:508
  static const busNext = '$_bus/bus.svg'; // 2156:500

  // ── 학식(2158:714) ───────────────────────────────────────────
  static const _meal = 'assets/design_system/meal';
  static const mealBreakfast = '$_meal/breakfast.svg'; // 2158:750
  static const mealLunch = '$_meal/lunch.svg'; // 2158:765
  static const mealDinner = '$_meal/dinner.svg'; // 2158:790
  static const mealPin = '$_meal/pin.svg'; // 2158:744

  // ── 빈 강의실(2158:806) ─────────────────────────────────────
  static const floor = 'assets/design_system/empty_class/floor.svg'; // 2158:827

  // ── 학과/부서 조직도(2158:882) ──────────────────────────────
  static const _org = 'assets/design_system/organization';
  static const orgSearch = '$_org/search.svg'; // 2158:885
  static const orgAvatar = '$_org/avatar.svg'; // 2158:897 (흰 선, 진회색 원 위)
  static const orgPhone = '$_org/phone.svg'; // 2158:902
  static const orgMail = '$_org/mail.svg'; // 2158:905
  static const orgFolder = '$_org/folder.svg'; // 2158:912

  // ── 마이페이지(2158:997 · 2195:462 · 2195:503) ──────────────
  static const _my = 'assets/design_system/my';
  static const myLogout = '$_my/logout.svg'; // 2195:478
  static const myAvatar = '$_my/avatar.svg'; // 2158:1018 (흰 선, 진회색 원 위)
  static const myLoginMascot = '$_my/login_mascot.svg'; // 2195:464
  static const myBell = '$_my/bell.svg'; // 2196:534
  static const myGift = '$_my/gift.svg'; // 2196:528
  static const myMegaphone = '$_my/megaphone.svg'; // 2196:542
  static const myNotice = '$_my/notice.svg'; // 2196:567
  static const myFaq = '$_my/faq.svg'; // 2196:572
  static const myInquiry = '$_my/inquiry.svg'; // 2196:577
  static const myInfo = '$_my/info.svg'; // 2196:585
  static const myTerms = '$_my/terms.svg'; // 2196:742
  static const myVersion = '$_my/version.svg'; // 2196:749
  static const myLeave = '$_my/leave.svg'; // 2196:753
  static const myWithdrawMascot =
      '$_my/withdraw_mascot.svg'; // 2196:693 (우는 산돌이)
  static const myNoticeInfo = '$_my/notice_info.svg'; // 2196:1208 (진회색 ⓘ)

  // ── 하단 네비(2086:23) ───────────────────────────────────────
  static const navHome = '$_home/nav_home.svg';
  static const navHomeActive = '$_home/nav_home_active.svg'; // 2153:399
  static const navMeal = '$_home/nav_meal.svg';
  static const navBus = '$_home/nav_bus.svg';
  static const navNotice = '$_home/nav_notice.svg';
  static const navEmptyClass = '$_home/nav_empty_class.svg';
}
