import 'package:handol/features/notice/domain/model/notice.dart';

abstract class NoticeRepository {
  Future<({List<Notice> items, int total})> getNotices({
    int page = 1,
    int size = 10,
  });

  Future<({List<Notice> items, int total})> getDormitoryNotices({
    int page = 1,
    int size = 10,
  });
}
