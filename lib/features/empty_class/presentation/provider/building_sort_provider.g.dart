// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'building_sort_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$buildingSortControllerHash() =>
    r'e50fb004c9c7b3a23d5fdbf15130f2851ebb93e1';

/// 홈 카드 정렬 설정. 기기 로컬에 저장한다.
///
/// 저장소는 프로젝트가 SharedPreferences 대신 쓰는 flutter_secure_storage.
/// 저장이 실패해도 메모리 상태는 유지되므로 화면이 되돌아가지 않는다.
/// 계정 간 동기화가 필요해지면 user service 에 저장 API 를 두고
/// [_load] / [_save] 만 바꾸면 된다.
///
/// Copied from [BuildingSortController].
@ProviderFor(BuildingSortController)
final buildingSortControllerProvider = AsyncNotifierProvider<
  BuildingSortController,
  BuildingSortSettings
>.internal(
  BuildingSortController.new,
  name: r'buildingSortControllerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$buildingSortControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BuildingSortController = AsyncNotifier<BuildingSortSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
