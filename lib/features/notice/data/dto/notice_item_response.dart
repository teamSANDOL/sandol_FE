import 'package:json_annotation/json_annotation.dart';
import 'package:handori/features/notice/domain/model/notice.dart';

part 'notice_item_response.g.dart';

@JsonSerializable()
class NoticeItemResponse {
  final int id;
  final String url;
  final String title;
  // 서버 응답의 `html`(항목당 100~280KB 원문)은 받지 않는다. 앱은 [url]을
  // WebView 로 열고, json_serializable 은 선언하지 않은 키를 무시한다.
  final String author;
  final String createAt; // 서버 필드명 그대로 사용 (createAt)

  const NoticeItemResponse({
    required this.id,
    required this.url,
    required this.title,
    required this.author,
    required this.createAt,
  });

  factory NoticeItemResponse.fromJson(Map<String, dynamic> json) =>
      _$NoticeItemResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NoticeItemResponseToJson(this);

  Notice toDomain() => Notice(
        id: id,
        url: url,
        title: title,
        author: author,
        createdAt: createAt,
      );
}
