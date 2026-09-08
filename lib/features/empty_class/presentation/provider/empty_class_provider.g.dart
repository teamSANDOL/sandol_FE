// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'empty_class_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$classroomApiHash() => r'016aba35a7c3cd8cfe2dd201a37808c4991a2e29';

/// See also [classroomApi].
@ProviderFor(classroomApi)
final classroomApiProvider = AutoDisposeProvider<ClassroomApi>.internal(
  classroomApi,
  name: r'classroomApiProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$classroomApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClassroomApiRef = AutoDisposeProviderRef<ClassroomApi>;
String _$emptyClassRepositoryHash() =>
    r'9441cce318a04c6cb9b0d2ce7c30df740bfd9bd7';

/// 건물 전체 강의실 수를 내부 캐시하므로 keepAlive.
///
/// Copied from [emptyClassRepository].
@ProviderFor(emptyClassRepository)
final emptyClassRepositoryProvider = Provider<EmptyClassRepository>.internal(
  emptyClassRepository,
  name: r'emptyClassRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$emptyClassRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EmptyClassRepositoryRef = ProviderRef<EmptyClassRepository>;
String _$emptyClassesHash() => r'62796fb63f70d2d1d980a92afd18601c079422fa';

/// See also [emptyClasses].
@ProviderFor(emptyClasses)
final emptyClassesProvider =
    AutoDisposeFutureProvider<List<EmptyClass>>.internal(
      emptyClasses,
      name: r'emptyClassesProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$emptyClassesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EmptyClassesRef = AutoDisposeFutureProviderRef<List<EmptyClass>>;
String _$nearbyEmptyClassesHash() =>
    r'c4ee5a229e260d2431c880ae5c46002bfc012314';

/// 내 위치 정렬은 거리순(위치를 모르면 빈 강의실 많은 순), 내 순서 정렬은
/// 기기에 저장된 순서. 좌표가 없는 건물은 거리순에서 항상 뒤로 간다.
///
/// Copied from [nearbyEmptyClasses].
@ProviderFor(nearbyEmptyClasses)
final nearbyEmptyClassesProvider =
    AutoDisposeFutureProvider<List<NearbyEmptyClass>>.internal(
      nearbyEmptyClasses,
      name: r'nearbyEmptyClassesProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$nearbyEmptyClassesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NearbyEmptyClassesRef =
    AutoDisposeFutureProviderRef<List<NearbyEmptyClass>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
