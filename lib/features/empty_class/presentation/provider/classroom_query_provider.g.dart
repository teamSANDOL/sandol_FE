// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_query_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$classroomQueryControllerHash() =>
    r'cf3dc681020a4facb0eaa0eadcbb0272830e105f';

/// 홈 카드와 상세 지도가 함께 보는 조회 구간.
/// keepAlive 라 앱이 살아 있는 동안 사용자가 고른 구간과 축 기준 시각을 유지한다.
///
/// Copied from [ClassroomQueryController].
@ProviderFor(ClassroomQueryController)
final classroomQueryControllerProvider =
    NotifierProvider<ClassroomQueryController, ClassroomQuery>.internal(
      ClassroomQueryController.new,
      name: r'classroomQueryControllerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$classroomQueryControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ClassroomQueryController = Notifier<ClassroomQuery>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
