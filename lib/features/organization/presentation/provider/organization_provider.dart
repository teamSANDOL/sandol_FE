import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/network/static_info_dio_provider.dart';
import 'package:handori/features/organization/data/data_source/organization_api.dart';
import 'package:handori/features/organization/data/repository/organization_repository_impl.dart';
import 'package:handori/features/organization/domain/model/organization_node.dart';
import 'package:handori/features/organization/domain/model/organization_search_result.dart';
import 'package:handori/features/organization/domain/repository/organization_repository.dart';

part 'organization_provider.g.dart';

@riverpod
OrganizationApi organizationApi(Ref ref) {
  final dio = ref.watch(staticInfoDioProvider);
  return OrganizationApi(dio);
}

@riverpod
OrganizationRepository organizationRepository(Ref ref) {
  final api = ref.watch(organizationApiProvider);
  return OrganizationRepositoryImpl(api);
}

@riverpod
class OrganizationTreeNotifier extends _$OrganizationTreeNotifier {
  @override
  Future<OrganizationGroupNode> build() async {
    final repo = ref.watch(organizationRepositoryProvider);
    return repo.getTree();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(organizationRepositoryProvider).getTree(),
    );
  }
}

/// 조직도 검색. 서버 검색 API가 완전일치만 지원하므로
/// 트리 프로바이더의 데이터를 앱 안에서 부분일치로 필터링한다.
@riverpod
Future<List<OrganizationSearchResult>> organizationSearch(
  Ref ref,
  String query,
) async {
  if (query.trim().isEmpty) return const [];
  final root = await ref.watch(organizationTreeNotifierProvider.future);
  return searchOrganizationTree(root, query);
}
