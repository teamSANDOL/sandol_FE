import 'package:flutter/material.dart';
import 'package:handori/core/design_system/handol_assets.dart';
import 'package:handori/core/design_system/handol_tokens.dart';

class HandolBrand extends StatelessWidget {
  const HandolBrand({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Image.asset(
      HandolAssets.welcomeLogo,
      width: HandolMetrics.logoSize,
      height: HandolMetrics.logoSize,
      fit: BoxFit.contain,
      semanticLabel: '한돌이',
    ),
  );
}
