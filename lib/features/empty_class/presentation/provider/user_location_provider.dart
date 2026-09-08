import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_location_provider.g.dart';

/// 당겨서 새로고침 때 위치를 다시 잡아도 되는지.
///
/// 위치 서비스가 꺼져 있거나 사용자가 "다시 묻지 않음"으로 거부했으면 시도해도
/// 결과가 같고 권한 창만 성가시므로 건너뛴다. 한 번 거부한 상태(denied)는
/// 처음에 GPS 가 꺼져 있어 묻지도 못한 경우가 많으니 다시 시도한다(플랫폼이
/// 재요청 횟수를 제한한다).
Future<bool> canRetryLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final permission = await Geolocator.checkPermission();
    return permission != LocationPermission.deniedForever &&
        permission != LocationPermission.unableToDetermine;
  } catch (_) {
    return false;
  }
}

bool _isGranted(LocationPermission p) =>
    p == LocationPermission.always || p == LocationPermission.whileInUse;

/// 현재 위치. 권한이 없거나 못 얻으면 null (에러로 취급하지 않는다).
///
/// 홈에서 처음 watch 될 때 권한을 요청한다. 다시 시도하려면
/// `ref.invalidate(userLocationProvider)`.
@Riverpod(keepAlive: true)
Future<Position?> userLocation(Ref ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!_isGranted(permission)) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      // 실내 등으로 현재 위치가 늦으면 마지막 위치라도 쓴다.
      return await Geolocator.getLastKnownPosition();
    }
  } catch (_) {
    return null;
  }
}
