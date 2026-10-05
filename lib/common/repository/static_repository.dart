import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/home/model/schedule_event.dart';

class StaticDataRepository {
  /// 홈 '주요일정'. 학사일정 API가 생기기 전까지의 자리표시 데이터.
  // TODO: 실제 학사일정으로 교체한다.
  /// 시안(2153:219)의 'Techno Festival · D-10 · 3일간'을 오늘 기준으로
  /// 재현한다. 날짜를 고정하면 지나간 뒤 홈이 곧바로 빈 카드가 된다.
  List<ScheduleEvent> get scheduleEvents {
    final today = KoreaTime.now();
    final start = DateTime(today.year, today.month, today.day + 10);
    return [
      ScheduleEvent(
        title: 'Techno Festival',
        start: start,
        end: DateTime(start.year, start.month, start.day + 2),
      ),
    ];
  }

}
