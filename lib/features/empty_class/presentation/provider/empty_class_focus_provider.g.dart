// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'empty_class_focus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$emptyClassFocusControllerHash() =>
    r'fb782dd0be73260d7d32d97c5284248d9721d0a2';

/// 홈에서 누른 건물을 상세 지도에 넘기는 일회성 요청.
///
/// 상세 화면은 탭 브랜치라 push 인자를 받을 수 없어 상태로 전달한다.
/// 상세가 처리하고 나면 [consume] 으로 비운다.
///
/// Copied from [EmptyClassFocusController].
@ProviderFor(EmptyClassFocusController)
final emptyClassFocusControllerProvider =
    NotifierProvider<EmptyClassFocusController, String?>.internal(
      EmptyClassFocusController.new,
      name: r'emptyClassFocusControllerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$emptyClassFocusControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EmptyClassFocusController = Notifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
