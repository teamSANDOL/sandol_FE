import 'package:flutter/material.dart';
import 'package:handori/core/constants/app_text_styles.dart';
import 'package:handori/features/organization/domain/model/organization_search_result.dart';
import 'package:handori/features/organization/presentation/widget/organization_node_card.dart';

/// 검색 결과 한 건: 상위 경로(브레드크럼) + 노드 카드.
class OrganizationSearchResultCard extends StatelessWidget {
  final OrganizationSearchResult result;

  const OrganizationSearchResultCard({required this.result, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.path.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6),
            child: Text(
              result.path.join(' › '),
              style: AppTextStyles.caption04.copyWith(color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        OrganizationNodeCard(node: result.node),
      ],
    );
  }
}
