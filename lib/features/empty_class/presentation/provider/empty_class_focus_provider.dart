import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'empty_class_focus_provider.g.dart';

/// 홈에서 누른 건물을 상세 지도에 넘기는 일회성 요청.
///
/// 상세 화면은 탭 브랜치라 push 인자를 받을 수 없어 상태로 전달한다.
/// 상세가 처리하고 나면 [consume] 으로 비운다.
@Riverpod(keepAlive: true)
class EmptyClassFocusController extends _$EmptyClassFocusController {
  @override
  String? build() => null;

  void request(String buildingName) => state = buildingName;

  String? consume() {
    final name = state;
    state = null;
    return name;
  }
}
