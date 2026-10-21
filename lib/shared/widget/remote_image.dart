import 'package:flutter/material.dart';
import 'package:handori/core/design_system/sandol_tokens.dart';

/// 서버 이미지([url])가 있으면 그것을, 없거나 받지 못하면 앱 에셋([asset]),
/// 에셋도 없으면 [placeholder]를 보여 준다. 크기는 부모가 정한다.
///
/// 받는 동안에는 [placeholder]를 둔다. 에셋을 먼저 보였다가 서버 사진으로
/// 바뀌면 다른 사진이 번쩍이기 때문이다.
// ponytail: Image.network 는 메모리 캐시뿐이라 앱을 다시 켜면 다시 받는다.
// 서버가 실제로 사진을 주기 시작하면 cached_network_image 로 디스크 캐시를 붙인다.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    this.url,
    this.asset,
    this.placeholder = const ColoredBox(color: SandolColors.primarySoft),
    this.fit = BoxFit.cover,
  });

  final String? url;
  final String? asset;
  final Widget placeholder;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final local = asset;
    final fallback = local == null ? placeholder : Image.asset(local, fit: fit);
    final remote = url;
    if (remote == null || remote.isEmpty) return fallback;
    return Image.network(
      remote,
      fit: fit,
      frameBuilder:
          (_, child, frame, sync) =>
              sync || frame != null ? child : placeholder,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
