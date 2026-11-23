import 'package:handol/features/notice/data/data_source/notice_api.dart';
import 'package:handol/features/notice/domain/model/notice.dart';
import 'package:handol/features/notice/domain/repository/notice_repository.dart';

class NoticeRepositoryImpl implements NoticeRepository {
  final NoticeApi _api;

  const NoticeRepositoryImpl(this._api);

  @override
  Future<({List<Notice> items, int total})> getNotices({
    int page = 1,
    int size = 10,
  }) async {
    final response = await _api.getNotices(page, size);
    return response.toDomain();
  }

  @override
  Future<({List<Notice> items, int total})> getDormitoryNotices({
    int page = 1,
    int size = 10,
  }) async {
    final response = await _api.getDormitoryNotices(page, size);
    return response.toDomain();
  }
}
