import 'package:flutter/painting.dart';

/// 앱 전체 모서리 반지름. 모든 컴포넌트가 이 값 하나를 쓴다.
abstract final class AppRadius {
  static const double value = 12;

  static const Radius radius = Radius.circular(value);
  static const BorderRadius all = BorderRadius.all(radius);
  static const BorderRadius top = BorderRadius.vertical(top: radius);
}
