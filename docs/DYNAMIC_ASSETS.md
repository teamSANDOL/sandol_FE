# 서버에서 받을 수 있는 에셋·데이터 (TASK-123)

앱에 박혀 있지만 바뀔 수 있는 데이터와 이미지를 정리하고, 서버에서 받도록
바꾼 것과 서버 필드가 생기면 바로 쓰도록 준비한 것을 적는다. 뒤쪽
「백엔드 요청」은 백엔드에 그대로 전달할 수 있게 썼다.

## 대체 순서 원칙

원격 우선 + 대체는 필요한 곳에만 둔다.

| 대상 | 1순위 | 2순위 | 3순위 |
|---|---|---|---|
| 셔틀 시간표 | 서버 `GET /static-info/bus/timetable` | 기기 캐시(마지막 성공 응답) | 앱 내장 시간표 |
| 학식 사진 | 끼니(Meal) `image_url` | 식당(Restaurant) `image_url` | 식당 이름 → 앱 에셋, 없으면 자리표시 |
| TUK 월드 사진 | 서버 `images[].url` | — | 분류 아이콘 자리표시 |

- 셔틀: 앱을 켜면 캐시를 먼저 올리고 서버 응답으로 바꾼다. 서버가 실패했거나
  쓸 수 있는 노선이 없으면(빈 응답 포함) 캐시를 덮어쓰지 않는다. 캐시는
  `FlutterSecureStorage` 키 `bus.shuttle_timetable`에 응답 원문을 저장한다.
  코드: `lib/features/bus/presentation/provider/next_shuttle_provider.dart`
  (`ShuttleScheduleSource`), 변환: `lib/features/bus/data/data_source/remote_shuttle_schedule.dart`.
- 이미지: `lib/shared/widget/remote_image.dart`(`RemoteImage`). 받는 동안과
  실패 시에는 자리표시나 에셋을 보여 준다. 현재 디스크 캐시는 없고(메모리 캐시만)
  서버가 실제로 사진을 주기 시작하면 `cached_network_image`를 붙인다.
- 상대 경로 규칙: `lib/core/utils/remote_url.dart`(`resolveRemoteUrl`). 응답을 준
  서버 주소를 알면 그 기준으로, 모르면 그 서비스의 기본 주소(`https://sandori.kr`)
  기준으로 푼다. 절대 주소는 그대로 쓴다.

## 전수 조사

변경 빈도는 추정이다. 방침: **전환**(이번에 서버 우선으로 바꿈) / **준비**(서버
필드가 생기면 앱 수정 없이 씀) / **유지**(지금은 앱에 둠).

| 항목 | 위치 | 서버 API | 변경 빈도 | 방침 |
|---|---|---|---|---|
| 셔틀 시간표 | `lib/features/bus/data/data_source/shuttle_schedule_data.dart:14` | 있음 `GET /static-info/bus/timetable` | 학기·방학마다 | **전환** (노선별, 아래 「셔틀」 참고) |
| 셔틀 도착버스 승차 안내 문구 | `shuttle_schedule_data.dart:19` | 없음(trip `boarding_place`로 줄 수 있음) | 드묾 | **준비**: 비고에 `도착버스` + `boarding_place`가 오면 사용 |
| 공휴일 목록 | `lib/features/bus/data/data_source/korean_public_holidays.dart:14` | 없음 | 매년(+임시공휴일) | 유지. 서버 `day_type`은 trip 분류일 뿐 오늘이 공휴일인지 알려 주지 않는다 |
| 셔틀 정류장 좌표(가까운 출발지 선택) | `lib/features/bus/domain/usecase/nearest_shuttle_origin.dart:11` | 없음 | 거의 없음 | 유지 |
| 셔틀 정류장 표기(`한국공학대 정문` 등) | `lib/features/bus/component/bus_time_card.dart:35` | 서버는 `본교`·`정왕역`·`제2캠퍼스`만 씀 | 거의 없음 | 유지(앱 표기, 서버 이름과 매핑) |
| 학식 식당 사진 | `lib/features/school_meal/presentation/model/restaurant_menu.dart:144` | 없음 | 식당 추가·교체 시 | **준비**: 식당 `image_url` |
| 학식 메뉴(끼니) 사진 | (없음, 새 기능) | 없음 | 매 끼니 | **준비**: 끼니 `image_url`이 오면 식당 사진보다 먼저 |
| 학식 식당 위치 대체 표기 | `restaurant_menu.dart:135` | 있음 `location.building`(일부 식당 누락) | 드묾 | 유지(서버 값 우선, 없을 때만 대체) |
| 빈 강의실 건물 좌표·아이콘 | `lib/features/empty_class/data/building_locations.dart:15` | 없음 | 거의 없음 | 유지 |
| 빈 강의실 혼잡도 아이콘 | `lib/features/empty_class/data/repository/empty_class_repository_impl.dart:93` | 해당 없음(UI) | 없음 | 유지 |
| 맵 교내시설 바로가기(식당·카페·프린트 등) | `lib/features/map/component/map_common.dart:25` | 없음(위치·운영 API 없음, 누르면 '준비중') | 시설 API 생길 때 | 유지. 시설 API가 생기면 별도 작업 |
| 맵 기본 중심 좌표 | `lib/features/map/screen/map_screen.dart:73` | 해당 없음 | 없음 | 유지 |
| TUK 월드 업체·사진 | `lib/features/map/data/tuk_place.dart` | 있음 `GET /static-info/tuk-world/restaurants` | 수시 | 이미 서버. 상대 경로 규칙을 공용화 |
| 셔틀 공지 이미지(iBook) | `lib/features/notice/presentation/widget/shuttle_card.dart:51` | 있음(서버 URL) | 학기마다 | 이미 서버 |
| 홈 고정 부서 | `lib/features/organization/presentation/provider/organization_provider.dart:54` | 조직도는 있음, 고정 목록은 없음 | 드묾 | 유지(이름이 트리에 없으면 조용히 빠짐) |
| 홈 주요일정 | `lib/common/repository/static_repository.dart:9` | 없음(학사일정 API 없음) | 학기마다 | 유지(자리표시 데이터). 학사일정 API가 생기면 교체 |
| 스플래시 영상·포스터 | `lib/core/design_system/sandol_assets.dart:12` | 없음 | 드묾(브랜드 교체) | 유지. 첫 화면은 네트워크 전에 떠야 하므로 내장이 맞다 |
| 정책 URL(처리방침·계정 삭제) | `lib/core/constants/api_constants.dart:27` | 웹 페이지(주소 고정) | 거의 없음 | 유지. Play 콘솔 등록 주소와 같아야 한다 |
| 로그인 버튼·아이콘·로고 등 디자인 에셋 | `lib/core/design_system/sandol_assets.dart` | 해당 없음 | 디자인 개편 시 | 유지(앱 업데이트로 배포) |

## 셔틀

### 변환 규칙 (서버 trip → 앱 시간표 항목)

| 서버 필드 | 앱 |
|---|---|
| `origin`·`destination` | 방향. `정왕역→본교` 등교, `본교→정왕역` 하교, 도착지 `제2캠퍼스` = 제2캠퍼스행(정왕역 출발 경유 포함), 출발지 `제2캠퍼스` = 본교행. `via`·`route` 문자열은 보지 않는다 |
| `day_type` | `평일`→평일, `토요일`→토요일, `주말`→토요일+일요일·공휴일, `일요일`·`공휴일`→일요일·공휴일(앱은 둘을 구분하지 않는다) |
| `departure_time` | 출발 시각 `HH:MM` |
| `departure_time_end` | 있으면 구간 항목. `note`에 `도착버스`가 있으면 도착버스 탑승(`boarding_place`를 승차 안내로), 아니면 수시운행 |

- 노선 단위 채택: 한 노선의 두 방향이 모두 응답에 있어야 그 노선을 서버 데이터로
  쓴다. 한 방향만 오면 파싱 누락으로 보고 그 노선은 내장 시간표를 쓴다.
- 방향 단위 보호: 내장 시간표에 있는 구간 종류(수시운행·도착버스 탑승)를 서버
  시간표가 하나라도 빠뜨리면 그 방향(그 요일)은 내장 시간표를 쓴다
  (`shuttleTimetableProvider`). 서버가 구간을 주기 시작하면 코드 수정 없이 풀린다.
- 오늘의 요일 구분(평일·토요일·일요일/공휴일)은 앱 공휴일 목록으로 정한다.
- 운행 기간(`valid_from`~`valid_to`) 필터와 중복 제거는 서버가 한다. 앱은 다시
  하지 않는다(오프라인이 학기 경계를 넘기면 지난 캐시가 남을 수 있다).

### 2026-10 운영 응답 점검 결과

- 정왕역↔본교: 하교 56편은 내장 시간표와 같다. 등교는 내장 시간표의
  「17:00~22:17 도착버스 탑승」이 응답에서 `22:17 막차` 한 줄로만 와서,
  17:00~22:17 사이 등교 카드가 「22:17 출발」로 보인다.
- 제2캠퍼스 노선: 18편이 모두 `본교 → 제2캠퍼스`로 오고 실제로는 두 방향 시각이
  섞여 있다(예: 09:40·10:30은 내장 시간표의 제2캠퍼스 출발 시각). 토요일 편도
  없다. 앱은 이 노선을 내장 시간표로 둔다.

### 현재 노선·방향별 데이터 원천 (2026-10 운영 응답 기준)

| 노선 | 방향 | 원천 | 이유 |
|---|---|---|---|
| 정왕역↔본교 | 본교 → 정왕역(하교) | 서버 | 수시운행 구간 포함, 내장과 같음 |
| 정왕역↔본교 | 정왕역 → 본교(등교) | 내장 | 서버가 도착버스 탑승 구간을 `22:17 막차`로만 줌(방향 단위 보호) |
| 제2캠퍼스 노선 | 본교 → 제2캠퍼스 | 내장 | 서버가 한 방향으로만 줌(노선 단위 채택 실패) |
| 제2캠퍼스 노선 | 제2캠퍼스 → 본교 | 내장 | 위와 같음 |

서버·캐시가 모두 없으면 전 방향이 내장 시간표다. 아래 요청 1·2가 반영되면 전
방향이 자동으로 서버 데이터로 바뀐다.

## 백엔드 요청

### static-info 셔틀 시간표

1. 제2캠퍼스 노선 방향 파싱 수정: `본교 → 제2캠퍼스`와 `제2캠퍼스 → 본교`
   (토요일은 `정왕역 → 본교 → 제2캠퍼스`, `제2캠퍼스 → 본교 → 정왕역`)을 나눠 주고,
   토요일 편을 포함해 달라. 고쳐지면 앱은 수정 없이 서버 데이터를 쓴다.
2. 도착버스 탑승 구간을 trip 하나로 달라:
   `departure_time: "17:00"`, `departure_time_end: "22:17"`,
   `note`에 `도착버스` 포함(예: `"도착버스 탑승 (막차 22:17)"`),
   `boarding_place`: 승차 위치(예: `"파리바게뜨 건너편 하차장소(버스정류장)"`).

### 학식(meal) 이미지

식당·끼니 응답에 아래 필드를 더해 달라. 없거나 `null`·빈 문자열이면 앱은 지금과
똑같이 보인다.

| 응답 | 필드 | 형식 | 의미 |
|---|---|---|---|
| 식당 (`/meal/restaurants/`, `/meal/restaurants/{id}`) | `image_url` | `string \| null` | 식당 대표 사진 |
| 끼니 (`/meal/meals*`) | `image_url` | `string \| null` | 그 끼니 메뉴 사진. 있으면 식당 사진 대신 보인다 |

- 값은 절대 주소(`https://...`) 또는 `/meal/...`처럼 `/`로 시작하는 경로. 경로면
  앱이 `https://sandori.kr` 기준으로 푼다.
- 이름은 기존 응답의 snake_case 규칙과 TUK 월드의 `url`에 맞춰 `image_url`로 했다.
  TUK 월드처럼 여러 장이 필요해지면 `images: [{url}]`로 따로 정하자.
- 이미지는 공개(인증 없이 GET)여야 한다. 앱은 이미지 요청에 토큰을 싣지 않는다.

## 남은 하드코딩

- 내장 셔틀 시간표·공휴일 목록: 서버·캐시가 모두 없을 때의 대체로 남는다. 학기·
  연도마다 갱신해야 한다(`shuttle_day_type_test`가 공휴일 목록 만료를 미리 알린다).
- 식당 이름 → 사진·위치 대체 표: 서버 필드가 채워지면 지워도 된다.
- 건물 좌표, 정류장 좌표, 교내시설 목록, 홈 주요일정, 고정 부서, 스플래시, 정책 URL:
  위 표의 「유지」 항목.
