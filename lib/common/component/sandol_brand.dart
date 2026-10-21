import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

class SandolBrand extends StatelessWidget {
  const SandolBrand({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Image.asset(
      SandolAssets.welcomeLogo,
      width: SandolMetrics.logoSize,
      height: SandolMetrics.logoSize,
      fit: BoxFit.contain,
      semanticLabel: '산돌이',
    ),
  );
}
