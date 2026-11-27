import { images } from '@/design-system';
import type { HomeBanner } from './model';

/**
 * 홈 배너 목록. 앞에서부터 보인다.
 * 앱 내장 목록. BFF 응답도 저장본도 없을 때만 쓴다(contentsApi.ts).
 */
export const homeBanners: readonly HomeBanner[] = [
  // 디자이너 임시 광고(2901:1129). 링크는 아직 정해지지 않아 눌리지 않는다.
  { title: 'Techno Festival 2026.09.29 ~ 2026.10.01', image: images.adFestival },
  { title: '오늘 학식, 한눈에', body: '식당별 오늘 메뉴와 운영 시간을 확인해요', icon: 'navMeal', link: { kind: 'app', location: '/meal' } },
  { title: '셔틀, 다음 출발까지', body: '정왕역·제2캠퍼스 셔틀 시간표를 바로 봐요', icon: 'navBus', link: { kind: 'app', location: '/bus' } },
  { title: '지금 빈 강의실 찾기', body: '지도에서 건물별 빈 강의실을 확인해요', icon: 'navMap', link: { kind: 'app', location: '/map' } },
  { title: '학교 공지 모아 보기', body: '놓치기 쉬운 학교 공지를 한곳에서 봐요', icon: 'navNotice', link: { kind: 'app', location: '/notice' } },
  { title: '학과·부서 연락처', body: '전화번호와 메일을 검색해서 바로 연락해요', icon: 'orgPhone', link: { kind: 'app', location: '/home/organization' } },
];
