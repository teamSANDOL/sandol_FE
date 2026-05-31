// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$restaurantApiHash() => r'7f10fececf93bfe6f44a64891446cb9b6e129600';

/// See also [restaurantApi].
@ProviderFor(restaurantApi)
final restaurantApiProvider = AutoDisposeProvider<RestaurantApi>.internal(
  restaurantApi,
  name: r'restaurantApiProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$restaurantApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RestaurantApiRef = AutoDisposeProviderRef<RestaurantApi>;
String _$restaurantRepositoryHash() =>
    r'01062e250d6d826b1c586defd56f40b898410222';

/// See also [restaurantRepository].
@ProviderFor(restaurantRepository)
final restaurantRepositoryProvider =
    AutoDisposeProvider<RestaurantRepository>.internal(
      restaurantRepository,
      name: r'restaurantRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$restaurantRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RestaurantRepositoryRef = AutoDisposeProviderRef<RestaurantRepository>;
String _$restaurantListNotifierHash() =>
    r'45fc68f55e6653621ea29f6519e43187d4ae7834';

/// See also [RestaurantListNotifier].
@ProviderFor(RestaurantListNotifier)
final restaurantListNotifierProvider = AutoDisposeAsyncNotifierProvider<
  RestaurantListNotifier,
  List<Restaurant>
>.internal(
  RestaurantListNotifier.new,
  name: r'restaurantListNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$restaurantListNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RestaurantListNotifier = AutoDisposeAsyncNotifier<List<Restaurant>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
