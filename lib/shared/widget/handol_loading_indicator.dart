import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 앱 공용 로딩 인디케이터.
///
/// CircularProgressIndicator 대신 이 위젯을 사용한다
/// (assets/lottie/handol_loading.json 애니메이션).
class HandolLoadingIndicator extends StatelessWidget {
  final double size;

  const HandolLoadingIndicator({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/handol_loading.json',
      width: size,
      height: size,
      repeat: true,
    );
  }
}
