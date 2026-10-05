import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/features/organization/domain/model/organization_search_result.dart';
import 'package:handori/features/organization/presentation/widget/organization_node_card.dart';

/// 검색 결과 한 건: 상위 경로(브레드크럼) + 노드.
class OrganizationSearchResultCard extends StatelessWidget {
  const OrganizationSearchResultCard({required this.result, super.key});

  final OrganizationSearchResult result;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (result.path.isNotEmpty)
        Text(
          result.path.join(' › '),
          style: SandolTypography.caption.muted,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      // 검색 결과는 경로를 이미 보여주므로 최상위처럼 들여쓰기 없이 그린다.
      OrganizationNodeCard(node: result.node, depth: 1),
    ],
  );
}
