import 'package:flutter/material.dart';
import 'package:handori/core/constants/app_colors.dart';

/// 섹션 제목 옆에 두는 작은 새로고침 버튼.
/// [onRefresh] 가 끝날 때까지(최소 0.5초) 아이콘 자리에 스피너를 보여준다.
class RefreshIconButton extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final double size;
  final Color color;
  final String tooltip;

  const RefreshIconButton({
    super.key,
    required this.onRefresh,
    this.size = 20,
    this.color = AppColors.textSecondary,
    this.tooltip = '새로고침',
  });

  @override
  State<RefreshIconButton> createState() => _RefreshIconButtonState();
}

class _RefreshIconButtonState extends State<RefreshIconButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Future.wait([
        widget.onRefresh().catchError((_) {}),
        Future<void>.delayed(const Duration(milliseconds: 500)),
      ]);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _busy ? null : _run,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: _busy
                ? Padding(
                    padding: EdgeInsets.all(widget.size * 0.15),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(Icons.refresh_rounded,
                    size: widget.size, color: widget.color),
          ),
        ),
      ),
    );
  }
}
