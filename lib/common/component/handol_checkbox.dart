import 'package:flutter/material.dart';
import 'package:handori/core/design_system/handol_tokens.dart';

class HandolCheckbox extends StatelessWidget {
  const HandolCheckbox({
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
        borderRadius: HandolMetrics.radius,
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
                          ? HandolColors.primary
                          : dense
                          ? HandolColors.inactive
                          : HandolColors.field,
                  border: Border.all(color: HandolColors.fieldBorder),
                  borderRadius: BorderRadius.circular(dense ? 6 : 12),
                ),
                child:
                    value
                        ? Icon(
                          Icons.check,
                          size: dense ? 16 : 22,
                          color: HandolColors.background,
                        )
                        : null,
              ),
              SizedBox(width: dense ? HandolSpacing.xs : HandolSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style:
                      dense
                          ? HandolTypography.caption.muted
                          : HandolTypography.body.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
