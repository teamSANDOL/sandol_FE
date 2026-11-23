import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 설치된 앱 버전 'v0.3.15' (pubspec version 의 빌드 번호 앞부분).
final appVersionProvider = FutureProvider<String>(
  (ref) async => 'v${(await PackageInfo.fromPlatform()).version}',
);
