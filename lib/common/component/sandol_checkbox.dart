import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

class SandolCheckbox extends StatelessWidget {
  const SandolCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.dense = false,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// 24px 회색 상자 + 캡션 라벨 (회원탈퇴 동의, Figma 2196:1207)
  final bool dense;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    checked: value,
    onTap: () => onChanged(!value),
    child: ExcludeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: SandolMetrics.radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: dense ? 24 : 32,
                height: dense ? 24 : 32,
                decoration: BoxDecoration(
                  color:
                      value
                          ? SandolColors.primary
                          : dense
                          ? SandolColors.inactive
                          : SandolColors.field,
                  border: Border.all(color: SandolColors.fieldBorder),
                  borderRadius: BorderRadius.circular(dense ? 6 : 12),
                ),
                child:
                    value
                        ? Icon(
                          Icons.check,
                          size: dense ? 16 : 22,
                          color: SandolColors.background,
                        )
                        : null,
              ),
              SizedBox(width: dense ? SandolSpacing.xs : SandolSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style:
                      dense
                          ? SandolTypography.caption.muted
                          : SandolTypography.body.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
