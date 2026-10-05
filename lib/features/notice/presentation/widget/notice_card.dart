import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/utils/date_formatter.dart';
import 'package:handori/features/notice/domain/model/notice.dart';

/// 공지 한 건 (Figma 2158:947): 작성 부서 · 제목(두 줄) · 날짜.
class NoticeCard extends StatelessWidget {
  const NoticeCard({required this.notice, this.onTap, super.key});

  final Notice notice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: SandolMetrics.radius,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SandolSpacing.sm,
      children: [
        Text(
          notice.author,
          style: SandolTypography.caption.copyWith(
            color: SandolColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          notice.title,
          style: SandolTypography.headline.muted,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          DateFormatter.dotted(notice.createdAt),
          style: SandolTypography.caption.muted,
        ),
      ],
    ),
  );
}
