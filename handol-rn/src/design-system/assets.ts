/**
 * 원본 노드별 Figma export (Flutter HandolAssets 이식).
 * SVG 는 컴포넌트, PNG·JPG·MP4 는 require 모듈이다.
 * 색을 바꿔 쓰는 아이콘(하단 네비)은 원본 색을 currentColor 로 바꿔 두었다 — color prop 으로 칠한다.
 */
import BackArrow from '../../assets/design_system/auth/back_arrow.svg';
import DividerLeft from '../../assets/design_system/auth/divider_left.svg';
import DividerRight from '../../assets/design_system/auth/divider_right.svg';
import Logo from '../../assets/design_system/home/logo.svg';
import User from '../../assets/design_system/home/user.svg';
import Chevron from '../../assets/design_system/home/chevron.svg';
import ChevronMuted from '../../assets/design_system/home/chevron_muted.svg';
import ArrowLeft from '../../assets/design_system/home/arrow_left.svg';
import Swap from '../../assets/design_system/home/swap.svg';
import Refresh from '../../assets/design_system/home/refresh.svg';
import Clock from '../../assets/design_system/home/clock.svg';
import BusStop from '../../assets/design_system/home/bus_stop.svg';
import BusDeparture from '../../assets/design_system/home/bus_departure.svg';
import Info from '../../assets/design_system/home/info.svg';
import Call from '../../assets/design_system/home/call.svg';
import NavHome from '../../assets/design_system/home/nav_home.svg';
import NavHomeActive from '../../assets/design_system/home/nav_home_active.svg';
import NavMeal from '../../assets/design_system/home/nav_meal.svg';
import NavBus from '../../assets/design_system/home/nav_bus.svg';
import NavNotice from '../../assets/design_system/home/nav_notice.svg';
import NavMap from '../../assets/design_system/home/nav_map.svg';
import BusStopPin from '../../assets/design_system/bus/pin.svg';
import BusStopFlag from '../../assets/design_system/bus/flag.svg';
import BusPinButton from '../../assets/design_system/bus/pin_button.svg';
import BusChevronButton from '../../assets/design_system/bus/chevron_button.svg';
import BusSwap from '../../assets/design_system/bus/swap.svg';
import BusRefresh from '../../assets/design_system/bus/refresh.svg';
import BusNext from '../../assets/design_system/bus/bus.svg';
import BusRow from '../../assets/design_system/bus/bus_row.svg';
import MealBreakfast from '../../assets/design_system/meal/breakfast.svg';
import MealLunch from '../../assets/design_system/meal/lunch.svg';
import MealDinner from '../../assets/design_system/meal/dinner.svg';
import MealPin from '../../assets/design_system/meal/pin.svg';
import Floor from '../../assets/design_system/empty_class/floor.svg';
import EmptyClassSetting from '../../assets/icon/emptyclass_setting.svg';
import OrgSearch from '../../assets/design_system/organization/search.svg';
import OrgAvatar from '../../assets/design_system/organization/avatar.svg';
import OrgPhone from '../../assets/design_system/organization/phone.svg';
import OrgMail from '../../assets/design_system/organization/mail.svg';
import OrgFolder from '../../assets/design_system/organization/folder.svg';
import MyLogout from '../../assets/design_system/my/logout.svg';
import MyAvatar from '../../assets/design_system/my/avatar.svg';
import MyLoginMascot from '../../assets/design_system/my/login_mascot.svg';
import MyBell from '../../assets/design_system/my/bell.svg';
import MyGift from '../../assets/design_system/my/gift.svg';
import MyMegaphone from '../../assets/design_system/my/megaphone.svg';
import MyNotice from '../../assets/design_system/my/notice.svg';
import MyFaq from '../../assets/design_system/my/faq.svg';
import MyInquiry from '../../assets/design_system/my/inquiry.svg';
import MyInfo from '../../assets/design_system/my/info.svg';
import MyTerms from '../../assets/design_system/my/terms.svg';
import MyVersion from '../../assets/design_system/my/version.svg';
import MyLeave from '../../assets/design_system/my/leave.svg';
import MyWithdrawMascot from '../../assets/design_system/my/withdraw_mascot.svg';
import MyNoticeInfo from '../../assets/design_system/my/notice_info.svg';
import MapCafe from '../../assets/design_system/map/cafe.svg';
import MapEmptyClass from '../../assets/design_system/map/empty_class.svg';
import MapLibrary from '../../assets/design_system/map/library.svg';
import MapPrinter from '../../assets/design_system/map/printer.svg';
import MapRestaurant from '../../assets/design_system/map/restaurant.svg';
import MapStore from '../../assets/design_system/map/store.svg';
import MapStudyRoom from '../../assets/design_system/map/study_room.svg';
import MapVending from '../../assets/design_system/map/vending.svg';

export const icons = {
  backArrow: BackArrow, // 2080:191
  dividerLeft: DividerLeft, // 2142:2400
  dividerRight: DividerRight, // 2142:2402
  logo: Logo, // 2530:10698 한돌이 BI
  user: User, // 2083:26
  /** 왼쪽을 향한다. Chevron 컴포넌트가 돌려 쓴다. */
  chevron: Chevron, // 2153:382
  chevronMuted: ChevronMuted, // 2156:439
  arrowLeft: ArrowLeft, // 2153:257
  swap: Swap, // 2153:260
  refresh: Refresh, // 2153:262
  clock: Clock, // 2153:268
  busStop: BusStop, // 2153:273
  busDeparture: BusDeparture, // 2153:279
  info: Info, // 2153:295
  call: Call, // 2153:362
  navHome: NavHome,
  navHomeActive: NavHomeActive, // 2153:399
  navMeal: NavMeal,
  navBus: NavBus,
  navNotice: NavNotice,
  navMap: NavMap, // 2086:39
  busStopPin: BusStopPin, // 2156:478
  busStopFlag: BusStopFlag, // 2156:485
  /** 아래 넷은 원형 배경이 SVG 안에 들어 있다. */
  busPinButton: BusPinButton, // 2162:1411
  busChevronButton: BusChevronButton, // 2162:1413
  busSwap: BusSwap, // 2156:474
  busRefresh: BusRefresh, // 2156:508
  busNext: BusNext, // 2156:500
  /** 시간표 줄 아이콘. 몸체가 currentColor 라 color prop 으로 칠한다. */
  busRow: BusRow, // 2683:3146
  mealBreakfast: MealBreakfast, // 2158:750
  mealLunch: MealLunch, // 2158:765
  mealDinner: MealDinner, // 2158:790
  mealPin: MealPin, // 2158:744
  floor: Floor, // 2158:827
  emptyClassSetting: EmptyClassSetting,
  orgSearch: OrgSearch, // 2158:885
  orgAvatar: OrgAvatar, // 2158:897
  orgPhone: OrgPhone, // 2158:902
  orgMail: OrgMail, // 2158:905
  orgFolder: OrgFolder, // 2158:912
  myLogout: MyLogout, // 2195:478
  myAvatar: MyAvatar, // 2158:1018
  myLoginMascot: MyLoginMascot, // 2195:464
  myBell: MyBell, // 2196:534
  myGift: MyGift, // 2196:528
  myMegaphone: MyMegaphone, // 2196:542
  myNotice: MyNotice, // 2196:567
  myFaq: MyFaq, // 2196:572
  myInquiry: MyInquiry, // 2196:577
  myInfo: MyInfo, // 2196:585
  myTerms: MyTerms, // 2196:742
  myVersion: MyVersion, // 2196:749
  myLeave: MyLeave, // 2196:753
  myWithdrawMascot: MyWithdrawMascot, // 2196:693 우는 한돌이
  myNoticeInfo: MyNoticeInfo, // 2196:1208
  mapCafe: MapCafe,
  mapEmptyClass: MapEmptyClass,
  mapLibrary: MapLibrary,
  mapPrinter: MapPrinter,
  mapRestaurant: MapRestaurant,
  mapStore: MapStore,
  mapStudyRoom: MapStudyRoom,
  mapVending: MapVending,
} as const;

export type IconName = keyof typeof icons;

/** 비트맵 · 영상 (require 모듈) */
export const images = {
  welcomeLogo: require('../../assets/design_system/auth/welcome_logo.png'), // 2889:1259
  kakao: require('../../assets/design_system/auth/kakao.png'), // 2143:2412
  google: require('../../assets/design_system/auth/google.png'), // 2143:2490
  apple: require('../../assets/design_system/auth/apple.png'), // 2195:509
  /** VIDEO fill(2219:447). 오디오 트랙 제거본 */
  splashVideo: require('../../assets/design_system/auth/splash.mp4'),
  /** 영상 준비 전 · 실패 시 첫 프레임 정지 이미지 */
  splashPoster: require('../../assets/design_system/auth/splash_art.png'),
  /** 홈 광고 카드 (2901:1129). 디자이너 임시 광고 */
  adFestival: require('../../assets/design_system/home/ad_festival.jpg'),
  mealGaga: require('../../assets/design_system/home/meal_gaga.png'), // 2153:238
  mealDasol: require('../../assets/design_system/home/meal_dasol.png'),
  mealMiga: require('../../assets/design_system/home/meal_miga.png'),
  mealSemicon: require('../../assets/design_system/home/meal_semicon.png'),
  /** 사진 없는 식당 (2901:1237) */
  mealNoPhoto: require('../../assets/design_system/meal/no_photo.jpg'),
  appIcon: require('../../assets/icon/app_icon.png'),
} as const;

export const lottie = {
  loading: require('../../assets/lottie/handol_loading.json'),
} as const;
