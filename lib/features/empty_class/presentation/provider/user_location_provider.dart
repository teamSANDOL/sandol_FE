import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_location_provider.g.dart';

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
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return null;
    }

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
