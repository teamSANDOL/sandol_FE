import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:handori/features/notice/domain/model/notice.dart';

/// 저장한 공지. 기기 로컬(flutter_secure_storage)에 공지 전체를 JSON 으로 둔다.
///
/// 공지 API 에 개별 조회가 없어 id 만 두면 목록 밖의 오래된 공지를 다시 못
/// 그린다. 저장이 실패해도 메모리 상태는 유지된다.
/// 계정 간 동기화가 필요하면 서버에 북마크 API 를 두고 [_load]/[_save]만 바꾼다.
class NoticeBookmarks extends Notifier<List<Notice>> {
  static const _key = 'notice.bookmarks';
  static const _storage = FlutterSecureStorage();

  @override
  List<Notice> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || state.isNotEmpty) return;
      state = [
        for (final m in jsonDecode(raw) as List)
          Notice(
            id: (m as Map<String, dynamic>)['id'] as int,
            url: m['url'] as String,
            title: m['title'] as String,
            author: m['author'] as String,
            createdAt: m['createdAt'] as String,
          ),
      ];
    } catch (_) {
      // 읽기 실패·손상된 값은 빈 목록으로 시작한다.
    }
  }

  Future<void> _save() async {
    try {
      await _storage.write(
        key: _key,
        value: jsonEncode([
          for (final n in state)
            {
              'id': n.id,
              'url': n.url,
              'title': n.title,
              'author': n.author,
              'createdAt': n.createdAt,
            },
        ]),
      );
    } catch (_) {
      // 저장 실패는 조용히 넘긴다. 다음 실행에서 목록이 비어 있을 뿐이다.
    }
  }

  bool isSaved(int id) => state.any((n) => n.id == id);

  /// 저장돼 있으면 빼고, 없으면 맨 앞에 넣는다.
  Future<void> toggle(Notice notice) async {
    state =
        isSaved(notice.id)
            ? state.where((n) => n.id != notice.id).toList()
            : [notice, ...state];
    await _save();
  }
}

final noticeBookmarksProvider =
    NotifierProvider<NoticeBookmarks, List<Notice>>(NoticeBookmarks.new);
