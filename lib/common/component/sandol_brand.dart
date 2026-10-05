import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

enum SandolBrandVariant { welcome, login, mascot }

class SandolBrand extends StatelessWidget {
  const SandolBrand({super.key, this.variant = SandolBrandVariant.welcome});
  final SandolBrandVariant variant;

  @override
  Widget build(BuildContext context) {
    final mascot = variant == SandolBrandVariant.mascot;
    return Center(
      child: Image.asset(
        switch (variant) {
          SandolBrandVariant.welcome => SandolAssets.welcomeLogo,
          SandolBrandVariant.login => SandolAssets.loginLogo,
          SandolBrandVariant.mascot => SandolAssets.signupMascot,
        },
        width: mascot ? 136.533 : SandolMetrics.logoSize,
        height: mascot ? 175 : SandolMetrics.logoSize,
        fit: BoxFit.contain,
        semanticLabel: '산돌이',
      ),
    );
  }
}
