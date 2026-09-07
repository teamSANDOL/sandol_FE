// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$organizationApiHash() => r'4a0cb73b5538d1d4dd0d48a12b43bfb019c41af1';

/// See also [organizationApi].
@ProviderFor(organizationApi)
final organizationApiProvider = AutoDisposeProvider<OrganizationApi>.internal(
  organizationApi,
  name: r'organizationApiProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$organizationApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrganizationApiRef = AutoDisposeProviderRef<OrganizationApi>;
String _$organizationRepositoryHash() =>
    r'71c659f098ed75c33af62bfe2a143429ea173913';

/// See also [organizationRepository].
@ProviderFor(organizationRepository)
final organizationRepositoryProvider =
    AutoDisposeProvider<OrganizationRepository>.internal(
      organizationRepository,
      name: r'organizationRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$organizationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrganizationRepositoryRef =
    AutoDisposeProviderRef<OrganizationRepository>;
String _$organizationSearchHash() =>
    r'be1d43a2c59a9993613a27e7e165234f1847667c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// 조직도 검색. 서버 검색 API가 완전일치만 지원하므로
/// 트리 프로바이더의 데이터를 앱 안에서 부분일치로 필터링한다.
///
/// Copied from [organizationSearch].
@ProviderFor(organizationSearch)
const organizationSearchProvider = OrganizationSearchFamily();

/// 조직도 검색. 서버 검색 API가 완전일치만 지원하므로
/// 트리 프로바이더의 데이터를 앱 안에서 부분일치로 필터링한다.
///
/// Copied from [organizationSearch].
class OrganizationSearchFamily
    extends Family<AsyncValue<List<OrganizationSearchResult>>> {
  /// 조직도 검색. 서버 검색 API가 완전일치만 지원하므로
  /// 트리 프로바이더의 데이터를 앱 안에서 부분일치로 필터링한다.
  ///
  /// Copied from [organizationSearch].
  const OrganizationSearchFamily();

  /// 조직도 검색. 서버 검색 API가 완전일치만 지원하므로
  /// 트리 프로바이더의 데이터를 앱 안에서 부분일치로 필터링한다.
  ///
  /// Copied from [organizationSearch].
  OrganizationSearchProvider call(String query) {
    return OrganizationSearchProvider(query);
  }

  @override
  OrganizationSearchProvider getProviderOverride(
    covariant OrganizationSearchProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'organizationSearchProvider';
}

/// 조직도 검색. 서버 검색 API가 완전일치만 지원하므로
/// 트리 프로바이더의 데이터를 앱 안에서 부분일치로 필터링한다.
///
/// Copied from [organizationSearch].
class OrganizationSearchProvider
    extends AutoDisposeFutureProvider<List<OrganizationSearchResult>> {
  /// 조직도 검색. 서버 검색 API가 완전일치만 지원하므로
  /// 트리 프로바이더의 데이터를 앱 안에서 부분일치로 필터링한다.
  ///
  /// Copied from [organizationSearch].
  OrganizationSearchProvider(String query)
    : this._internal(
        (ref) => organizationSearch(ref as OrganizationSearchRef, query),
        from: organizationSearchProvider,
        name: r'organizationSearchProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$organizationSearchHash,
        dependencies: OrganizationSearchFamily._dependencies,
        allTransitiveDependencies:
            OrganizationSearchFamily._allTransitiveDependencies,
        query: query,
      );

  OrganizationSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<OrganizationSearchResult>> Function(
      OrganizationSearchRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OrganizationSearchProvider._internal(
        (ref) => create(ref as OrganizationSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<OrganizationSearchResult>>
  createElement() {
    return _OrganizationSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OrganizationSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OrganizationSearchRef
    on AutoDisposeFutureProviderRef<List<OrganizationSearchResult>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _OrganizationSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<OrganizationSearchResult>>
    with OrganizationSearchRef {
  _OrganizationSearchProviderElement(super.provider);

  @override
  String get query => (origin as OrganizationSearchProvider).query;
}

String _$organizationTreeNotifierHash() =>
    r'0b24a2aa1628237634c330b4dbd3e162e0a99950';

/// See also [OrganizationTreeNotifier].
@ProviderFor(OrganizationTreeNotifier)
final organizationTreeNotifierProvider = AutoDisposeAsyncNotifierProvider<
  OrganizationTreeNotifier,
  OrganizationGroupNode
>.internal(
  OrganizationTreeNotifier.new,
  name: r'organizationTreeNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$organizationTreeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OrganizationTreeNotifier =
    AutoDisposeAsyncNotifier<OrganizationGroupNode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
