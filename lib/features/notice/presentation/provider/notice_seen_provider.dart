import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:handori/core/utils/date_formatter.dart';
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/notice/domain/model/notice.dart';

/// 지난번 공지 목록을 떠날 때 이미 있던 공지. 기기 로컬(flutter_secure_storage)에
/// `공지 키 → 게시일(KST yyyy-MM-dd)` 를 JSON 으로 둔다. `null` 은 첫 실행이다.
///
/// NEW = 게시일이 최근 [newWithinDays] 일 안이고 이 기록에 없는 공지.
/// 게시일에 시각이 없을 수 있어 날짜가 아니라 기록(키 집합)으로 "새로 올라온"
/// 공지를 가린다. 기록은 NEW 후보 기간 안의 공지만 담고 저장할 때마다 기간
/// 밖이 된 키를 버리므로 쌓이지 않는다. 저장이 실패해도 메모리 상태는 유지된다.
class NoticeSeen extends Notifier<Map<String, String>?> {
  /// 게시일이 KST 기준 오늘 포함 이 일수 안이면 NEW 후보.
  static const newWithinDays = 3;
  static const _key = 'notice.seen';
  static const _storage = FlutterSecureStorage();

  @override
  Map<String, String>? build() {
    _load();
    return null;
  }

  /// 공지 id 가 있으면 id, 없으면(0 이하) url.
  static String keyOf(Notice notice) =>
      notice.id > 0 ? '${notice.id}' : notice.url;

  /// 게시일의 KST 날짜(yyyy-MM-dd). 시간대 표기가 없으면 KST 벽시계로 본다.
  /// 파싱할 수 없으면 null.
  static String? _dateOf(Notice notice) {
    final created = DateTime.tryParse(notice.createdAt);
    if (created == null) return null;
    return DateFormatter.isoDate(
      created.isUtc ? created.add(KoreaTime.offset) : created,
    );
  }

  /// NEW 후보 기간의 첫 날짜. yyyy-MM-dd 라 문자열 비교가 날짜 비교다.
  static String _cutoff() => DateFormatter.isoDate(
    KoreaTime.now().subtract(const Duration(days: newWithinDays - 1)),
  );

  bool isNew(Notice notice) {
    final date = _dateOf(notice);
    if (date == null || date.compareTo(_cutoff()) < 0) return false;
    return !(state?.containsKey(keyOf(notice)) ?? false);
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || state != null) return;
      state = (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as String),
      );
    } catch (_) {
      // 읽기 실패·손상된 값은 첫 실행처럼 둔다(NEW 가 다시 보일 뿐).
    }
  }

  /// 목록을 떠나며, 그때 불러와 있던 [notices] 를 본 공지로 기록한다.
  Future<void> markSeen(Iterable<Notice> notices) async {
    final cutoff = _cutoff();
    state = {
      for (final e in (state ?? const <String, String>{}).entries)
        if (e.value.compareTo(cutoff) >= 0) e.key: e.value,
      for (final n in notices)
        if (_dateOf(n) case final date? when date.compareTo(cutoff) >= 0)
          keyOf(n): date,
    };
    try {
      await _storage.write(key: _key, value: jsonEncode(state));
    } catch (_) {
      // 저장 실패는 조용히 넘긴다. 다음 실행에서 NEW 가 다시 보일 뿐이다.
    }
  }
}

final noticeSeenProvider = NotifierProvider<NoticeSeen, Map<String, String>?>(
  NoticeSeen.new,
);
