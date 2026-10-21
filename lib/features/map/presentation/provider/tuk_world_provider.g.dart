// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tuk_world_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tukWorldApiHash() => r'912d8e389869ddfa1f9d2be6892dc86a768e733a';

/// See also [tukWorldApi].
@ProviderFor(tukWorldApi)
final tukWorldApiProvider = AutoDisposeProvider<TukWorldApi>.internal(
  tukWorldApi,
  name: r'tukWorldApiProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tukWorldApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TukWorldApiRef = AutoDisposeProviderRef<TukWorldApi>;
String _$tukWorldPlacesHash() => r'6ed1d6cac494d8028f29c1eb61720318d030530c';

/// TUK 월드 제휴 업체 전체. 분류 필터는 화면에서 한다(수십 곳 규모).
///
/// Copied from [tukWorldPlaces].
@ProviderFor(tukWorldPlaces)
final tukWorldPlacesProvider =
    AutoDisposeFutureProvider<List<TukPlace>>.internal(
      tukWorldPlaces,
      name: r'tukWorldPlacesProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$tukWorldPlacesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TukWorldPlacesRef = AutoDisposeFutureProviderRef<List<TukPlace>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
