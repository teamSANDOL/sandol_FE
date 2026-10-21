import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:handori/features/bus/domain/model/shuttle_schedule.dart';
import 'package:handori/features/bus/domain/usecase/nearest_shuttle_origin.dart';
import 'package:handori/features/bus/presentation/provider/next_shuttle_provider.dart';
import 'package:handori/features/empty_class/presentation/provider/user_location_provider.dart';

part 'shuttle_direction_provider.g.dart';

/// 셔틀 방향 선택(6방향). 홈 카드와 셔틀 상세 화면이 공유한다. 기본은
/// 정왕역 ↔ 본교 노선이고, 제2캠퍼스는 서버가 좌표를 줄 때만 자동 선택된다.
///
/// 위치를 얻으면 가까운 정류장을 출발지로 기본 선택하되, 사용자가 직접 바꾼
/// 뒤에는 위치가 갱신돼도 되돌리지 않는다. 위치는 홈이 이미 요청하는
/// [userLocationProvider]를 구독만 하므로 이 기능이 권한 창을 새로 띄우지 않는다.
/// 정류장 좌표는 [shuttleStopsProvider](서버 `stops`, 없으면 내장)를 쓴다.
@Riverpod(keepAlive: true)
class ShuttleDirectionSelection extends _$ShuttleDirectionSelection {
  bool _userChose = false;

  @override
  ShuttleDirection build() {
    ref.listen(userLocationProvider, (_, _) => _autoSelect());
    // 서버 정류장 좌표가 위치보다 늦게 와도 다시 고른다.
    ref.listen(shuttleStopsProvider, (_, _) => _autoSelect());
    return _nearest() ?? ShuttleDirection.schoolToJeongwang;
  }

  void _autoSelect() {
    final nearest = _nearest();
    if (_userChose || nearest == null) return;
    state = nearest;
  }

  /// 사용자가 직접 고른 방향. 이후 위치 갱신으로 덮어쓰지 않는다.
  void select(ShuttleDirection direction) {
    _userChose = true;
    state = direction;
  }

  /// 위치를 모르면 null.
  ShuttleDirection? _nearest() {
    final p = ref.read(userLocationProvider).value;
    if (p == null) return null;
    return NearestShuttleOrigin.fromPosition(
      p.latitude,
      p.longitude,
      ref.read(shuttleStopsProvider),
    );
  }
}
