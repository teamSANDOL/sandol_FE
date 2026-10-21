import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/core/utils/korea_time.dart';
import 'package:handori/features/notice/domain/model/notice.dart';
import 'package:handori/features/notice/presentation/provider/notice_seen_provider.dart';

void main() {
  late ProviderContainer container;

  Notice notice(int id, String createdAt) => Notice(
    id: id,
    url: 'https://example.com/$id',
    title: '공지 $id',
    author: '학사팀',
    createdAt: createdAt,
  );

  void at(int day) => KoreaTime.clock = () => DateTime.utc(2026, 10, day, 1);

  setUp(() {
    at(22); // 2026-10-22 10:00 KST
    container = ProviderContainer();
    addTearDown(container.dispose);
  });
  tearDown(() => KoreaTime.clock = DateTime.now);

  NoticeSeen seen() => container.read(noticeSeenProvider.notifier);

  test('첫 실행: 최근 3일(KST) 공지만 NEW', () {
    expect(seen().isNew(notice(1, '2026-10-22T00:30:00')), isTrue);
    expect(seen().isNew(notice(2, '2026-10-20T00:00:00')), isTrue);
    expect(seen().isNew(notice(3, '2026-10-19T23:59:00')), isFalse);
    // UTC 표기는 KST 로 바꿔 본다: 10-19 16:00Z = 10-20 01:00 KST
    expect(seen().isNew(notice(4, '2026-10-19T16:00:00Z')), isTrue);
    expect(seen().isNew(notice(5, '잘못된 값')), isFalse);
  });

  test('목록을 보고 떠나면 다음 방문부터 NEW 가 없다', () async {
    final a = notice(1, '2026-10-22T00:30:00');
    expect(seen().isNew(a), isTrue); // 이번 방문 동안은 그대로
    await seen().markSeen([a]);
    expect(seen().isNew(a), isFalse);
  });

  test('같은 날 새로 올라온 공지만 NEW', () async {
    final morning = notice(1, '2026-10-22T08:00:00');
    final afternoon = notice(2, '2026-10-22T13:00:00');
    await seen().markSeen([morning]);
    expect(seen().isNew(morning), isFalse);
    expect(seen().isNew(afternoon), isTrue);
  });

  test('id 가 없으면 url 이 키', () async {
    final n = notice(0, '2026-10-22T00:30:00');
    await seen().markSeen([n]);
    expect(container.read(noticeSeenProvider)!.keys, [n.url]);
  });

  test('기간 밖이 된 기록과 기간 밖 공지는 저장 시 정리', () async {
    at(19);
    await seen().markSeen([notice(1, '2026-10-19T09:00:00')]);
    at(21);
    await seen().markSeen([notice(2, '2026-10-21T09:00:00')]);
    expect(container.read(noticeSeenProvider)!.keys, {'1', '2'});
    at(22); // 컷오프 10-20: 10-19 기록 제거, 옛 공지(10-10)는 담지 않음
    await seen().markSeen([
      notice(3, '2026-10-22T09:00:00'),
      notice(4, '2026-10-10T09:00:00'),
    ]);
    expect(container.read(noticeSeenProvider)!.keys, {'2', '3'});
  });
}
