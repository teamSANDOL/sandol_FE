import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

enum SandolFieldSize {
  compact(8, 20),
  regular(9, 21),
  large(11, 21);

  const SandolFieldSize(this.verticalPadding, this.horizontalPadding);
  final double verticalPadding;
  final double horizontalPadding;
}

/// 입력/선택 필드가 라벨, 배경, 테두리, 오류 표시를 공유한다.
class SandolField extends StatelessWidget {
  const SandolField({
    super.key,
    this.label,
    required this.hint,
    required this.controller,
    this.password = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.onSubmitted,
    this.onTap,
    this.selection = false,
    this.autofillHints,
    this.hintMuted = true,
    this.size = SandolFieldSize.compact,
  });

  final String? label;
  final String hint;
  final TextEditingController controller;
  final bool password;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool selection;
  final Iterable<String>? autofillHints;
  final bool hintMuted;
  final SandolFieldSize size;

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: SandolMetrics.radius,
    borderSide: BorderSide(color: color),
  );

  @override
  Widget build(BuildContext context) {
    final input = TextField(
      controller: controller,
      obscureText: password,
      autocorrect: !password,
      enableSuggestions: !password,
      readOnly: selection,
      canRequestFocus: !selection,
      onTap: onTap,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      style: SandolTypography.body,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: SandolColors.field,
        hintText: hint,
        hintStyle: SandolTypography.body.copyWith(
          color: hintMuted ? SandolColors.muted : SandolColors.text,
        ),
        errorText: errorText,
        errorMaxLines: 3,
        errorStyle: SandolTypography.caption.copyWith(
          color: SandolColors.error,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: size.horizontalPadding,
          vertical: size.verticalPadding,
        ),
        enabledBorder: _border(SandolColors.fieldBorder),
        focusedBorder: _border(SandolColors.primary),
        errorBorder: _border(SandolColors.error),
        focusedErrorBorder: _border(SandolColors.error),
        suffixIconConstraints: const BoxConstraints(minWidth: 54),
        suffixIcon:
            selection
                ? SizedBox(
                  width: 54,
                  child: Center(
                    child: Transform.rotate(
                      angle: -math.pi / 2,
                      child: SvgPicture.asset(
                        SandolAssets.selectArrow,
                        width: 9,
                        height: 16,
                      ),
                    ),
                  ),
                )
                : null,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(label!, style: SandolTypography.caption),
          const SizedBox(height: SandolSpacing.xs),
        ],
        Semantics(label: label ?? hint, child: input),
      ],
    );
  }
}
