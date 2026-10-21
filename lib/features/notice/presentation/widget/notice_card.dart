import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';
import 'package:handori/core/utils/date_formatter.dart';
import 'package:handori/features/notice/domain/model/notice.dart';
import 'package:handori/features/notice/presentation/widget/notice_style.dart';

/// 공지 한 건 (Figma 공지사항2 > Frame 2147234780): 작성 부서 배지 · NEW ·
/// 저장 아이콘 / 제목 / 날짜. 본문 미리보기와 D-day 는 API 에 없어 그리지 않는다.
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    required this.notice,
    required this.saved,
    required this.onToggleSaved,
    this.onTap,
    super.key,
  });

  /// 올라온 지 이 일수 안이면 NEW 배지를 단다.
  static const newWithinDays = 7;

  final Notice notice;
  final bool saved;
  final VoidCallback onToggleSaved;
  final VoidCallback? onTap;

  bool get _isNew {
    final created = DateTime.tryParse(notice.createdAt);
    return created != null &&
        DateTime.now().difference(created).inDays < newWithinDays;
  }

  @override
  Widget build(BuildContext context) => Material(
    color: SandolColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: SandolMetrics.radius,
      side: BorderSide(color: NoticeColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SandolSpacing.xs,
          children: [
            Row(
              spacing: SandolSpacing.xs,
              children: [
                Flexible(child: _Badge(notice.author, SandolColors.primary)),
                if (_isNew) const _Badge('NEW', NoticeColors.badgeNew),
                const Spacer(),
                IconButton(
                  tooltip: saved ? '저장 해제' : '저장',
                  visualDensity: VisualDensity.compact,
                  onPressed: onToggleSaved,
                  icon: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 20,
                    color: saved ? SandolColors.primary : SandolColors.text,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                notice.title,
                style: SandolTypography.caption.strong.copyWith(
                  color: NoticeColors.title,
                  height: 22 / 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${DateFormatter.format(notice.createdAt)}.',
              style: SandolTypography.caption.copyWith(
                fontSize: 12,
                color: NoticeColors.meta,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: SandolTypography.caption.onPrimary,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
