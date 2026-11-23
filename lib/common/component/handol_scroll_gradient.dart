import 'package:flutter/material.dart';
import 'package:handol/core/design_system/handol_tokens.dart';

/// 스크롤 내용 전체에 걸쳐 번지는 화면 배경 그라데이션 (Figma R BAK).
///
/// 홈(1900) · 셔틀버스(1304) 시안은 프레임이 스크롤 전체 길이라 그라데이션도
/// 화면 하나가 아니라 내용 전체에 걸쳐 있다. 첫 화면은 거의 흰색이고 끝까지
/// 내려야 보라가 짙어진다. [controller]는 [child] 안 스크롤 뷰의 것이어야 한다.
class HandolScrollGradient extends StatefulWidget {
  const HandolScrollGradient({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  /// 스크롤 내용 전체 길이. 아직 레이아웃 전이면 null.
  static double? extentOf(ScrollController controller) {
    if (!controller.hasClients) return null;
    final pos = controller.position;
    if (!pos.hasContentDimensions) return null;
    return pos.maxScrollExtent + pos.viewportDimension;
  }

  @override
  State<HandolScrollGradient> createState() => _HandolScrollGradientState();
}

class _HandolScrollGradientState extends State<HandolScrollGradient> {
  /// 데이터가 늦게 와서 길이만 바뀔 때(오프셋은 그대로) 다시 그린다.
  final _extent = ValueNotifier(0);

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.controller, _extent]),
          builder: (context, _) {
            final extent = HandolScrollGradient.extentOf(widget.controller);
            return HandolGradientSlice(
              top: extent == null ? 0 : widget.controller.position.pixels,
              extent: extent ?? MediaQuery.sizeOf(context).height,
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (n) {
          // 학식 칩 같은 안쪽 가로 스크롤은 무시한다.
          if (n.depth == 0) _extent.value++;
          return false;
        },
        child: widget.child,
      ),
    ],
  );
}

/// 길이 [extent]인 배경 그라데이션 중 [top]부터 [child] 높이만큼을 [child]
/// 뒤에 깐다. 고정 헤더처럼 아래로 지나가는 내용을 가려야 하는 곳에 쓴다.
class HandolGradientSlice extends StatelessWidget {
  const HandolGradientSlice({
    super.key,
    required this.top,
    required this.extent,
    required this.child,
  });

  final double top;
  final double extent;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        top: -top,
        left: 0,
        right: 0,
        height: extent,
        child: const DecoratedBox(
          decoration: BoxDecoration(gradient: HandolGradients.screen),
        ),
      ),
      child,
    ],
  );
}
