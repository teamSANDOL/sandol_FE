import 'package:handol/core/design_system/handol_assets.dart';
import 'package:handol/core/router/route_paths.dart';
import 'package:handol/features/home/model/home_banner.dart';

/// 홈 배너 목록. 앞에서부터 보인다.
// ponytail: 앱에 박은 목록. BFF(docs/BFF_APP_CONTENT.md)가 생기면 그 응답으로
// 바꾸고 이 목록은 서버를 못 받을 때의 대체로 남긴다.
const homeBanners = <HomeBanner>[
  // 디자이너 임시 광고(2901:1129). 링크는 아직 정해지지 않아 눌리지 않는다.
  HomeBanner(
    title: 'Techno Festival 2026.09.29 ~ 2026.10.01',
    image: HandolAssets.adFestival,
  ),
  HomeBanner(
    title: '오늘 학식, 한눈에',
    body: '식당별 오늘 메뉴와 운영 시간을 확인해요',
    icon: HandolAssets.navMeal,
    link: AppBannerLink(RoutePaths.meal),
  ),
  HomeBanner(
    title: '셔틀, 다음 출발까지',
    body: '정왕역·제2캠퍼스 셔틀 시간표를 바로 봐요',
    icon: HandolAssets.navBus,
    link: AppBannerLink(RoutePaths.bus),
  ),
  HomeBanner(
    title: '지금 빈 강의실 찾기',
    body: '지도에서 건물별 빈 강의실을 확인해요',
    icon: HandolAssets.navMap,
    link: AppBannerLink(RoutePaths.map),
  ),
  HomeBanner(
    title: '학교 공지 모아 보기',
    body: '놓치기 쉬운 학교 공지를 한곳에서 봐요',
    icon: HandolAssets.navNotice,
    link: AppBannerLink(RoutePaths.notice),
  ),
  HomeBanner(
    title: '학과·부서 연락처',
    body: '전화번호와 메일을 검색해서 바로 연락해요',
    icon: HandolAssets.orgPhone,
    link: AppBannerLink(RoutePaths.organization),
  ),
];
