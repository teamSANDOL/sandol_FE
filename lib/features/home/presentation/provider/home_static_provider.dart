import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/common/repository/static_repository.dart';
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/home/model/schedule_event.dart';

part 'home_static_provider.g.dart';

// ── 주요일정 (정적 데이터) ───────────────────────────────────────────────────

@riverpod
List<ScheduleEvent> scheduleEvents(Ref ref) {
  return StaticDataRepository().scheduleEvents;
}

/// 고정을 해제한 일정 id. 기기에 저장해 앱을 다시 켜도 해제된 채로 둔다.
@Riverpod(keepAlive: true)
class DismissedSchedules extends _$DismissedSchedules {
  static const _key = 'home.dismissed_schedules';
  static const _storage = FlutterSecureStorage();

  @override
  Future<Set<String>> build() async {
    try {
      final raw = await _storage.read(key: _key);
      return raw == null
          ? {}
          : (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> dismiss(String id) async {
    final next = {...?state.valueOrNull, id};
    state = AsyncData(next);
    try {
      await _storage.write(key: _key, value: jsonEncode(next.toList()));
    } catch (_) {
      // 저장 실패는 조용히 넘긴다. 다음 실행에서 카드가 다시 보일 뿐이다.
    }
  }
}

/// 홈 주요일정: 끝나지 않았고 고정을 해제하지 않은 것 중 가장 먼저
/// 시작하는 것. 없으면 null(빈 카드). 해제 목록을 읽는 동안은 로딩이라
/// 빈 카드가 잠깐 보였다 바뀌지 않는다.
@riverpod
Future<ScheduleEvent?> homeSchedule(Ref ref) async {
  final dismissed = await ref.watch(dismissedSchedulesProvider.future);
  final today = KoreaTime.now();
  final events =
      ref
          .watch(scheduleEventsProvider)
          .where((e) => !e.isOverOn(today) && !dismissed.contains(e.id))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
  return events.firstOrNull;
}
