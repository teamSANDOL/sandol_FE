import 'package:handori/features/organization/domain/model/organization_node.dart';

/// 조직도 트리 안에서 검색에 걸린 노드와, 루트(제외)부터 그 노드까지의 상위 경로.
class OrganizationSearchResult {
  final OrganizationNode node;

  /// 상위 그룹 이름 목록. 예: ['대학본부', '교무처']
  final List<String> path;

  const OrganizationSearchResult({required this.node, required this.path});
}

/// 이미 받아둔 트리를 앱 안에서 부분일치로 검색한다.
///
/// 서버의 `/organization/search/{name}`은 이름 **완전일치**만 지원해
/// "감사" 같은 부분 검색에 빈 결과를 돌려주므로 사용하지 않는다.
/// - 이름: 공백 제거 + 대소문자 무시 후 `contains`
/// - 숫자만 입력하면 전화번호(숫자만)에도 `contains` 매칭
List<OrganizationSearchResult> searchOrganizationTree(
  OrganizationGroupNode root,
  String query,
) {
  final q = _normalize(query);
  if (q.isEmpty) return const [];
  final digitQuery = RegExp(r'^\d+$').hasMatch(q) ? q : null;

  final results = <OrganizationSearchResult>[];

  void visit(OrganizationNode node, List<String> path) {
    final nameHit = _normalize(node.name).contains(q);
    final phoneHit =
        digitQuery != null &&
        node is OrganizationUnitNode &&
        node.phone != null &&
        node.phone!.replaceAll(RegExp(r'\D'), '').contains(digitQuery);
    if (nameHit || phoneHit) {
      results.add(OrganizationSearchResult(node: node, path: path));
    }
    if (node is OrganizationGroupNode) {
      final childPath = [...path, node.name];
      for (final child in node.children) {
        visit(child, childPath);
      }
    }
  }

  for (final child in root.children) {
    visit(child, const []);
  }
  return results;
}

String _normalize(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();
