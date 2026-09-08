// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userLocationHash() => r'4e2796cab4603425a4a5b44dfc12122afbae1752';

/// 현재 위치. 권한이 없거나 못 얻으면 null (에러로 취급하지 않는다).
///
/// 홈에서 처음 watch 될 때 권한을 요청한다. 다시 시도하려면
/// `ref.invalidate(userLocationProvider)`.
///
/// Copied from [userLocation].
@ProviderFor(userLocation)
final userLocationProvider = FutureProvider<Position?>.internal(
  userLocation,
  name: r'userLocationProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userLocationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserLocationRef = FutureProviderRef<Position?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
