import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/nearest_shuttle_origin.dart';
import 'package:handori/features/empty_class/presentation/provider/user_location_provider.dart';

part 'shuttle_direction_provider.g.dart';

/// 노선1 방향 선택. 홈 카드와 셔틀 상세 화면이 공유한다.
///
/// 위치를 얻으면 가까운 정류장을 출발지로 기본 선택하되, 사용자가 직접 바꾼
/// 뒤에는 위치가 갱신돼도 되돌리지 않는다. 위치는 홈이 이미 요청하는
/// [userLocationProvider]를 구독만 하므로 이 기능이 권한 창을 새로 띄우지 않는다.
@Riverpod(keepAlive: true)
class ShuttleDirectionSelection extends _$ShuttleDirectionSelection {
  bool _userChose = false;

  @override
  ShuttleDirection build() {
    ref.listen(userLocationProvider, (_, next) {
      final position = next.value;
      if (_userChose || position == null) return;
      state = _nearest(position);
    });
    final position = ref.read(userLocationProvider).value;
    return position == null
        ? ShuttleDirection.schoolToJeongwang
        : _nearest(position);
  }

  /// 사용자가 직접 고른 방향. 이후 위치 갱신으로 덮어쓰지 않는다.
  void select(ShuttleDirection direction) {
    _userChose = true;
    state = direction;
  }

  static ShuttleDirection _nearest(Position p) =>
      NearestShuttleOrigin.fromPosition(p.latitude, p.longitude);
}
