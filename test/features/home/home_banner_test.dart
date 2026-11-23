import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:handol/core/design_system/handol_assets.dart';
import 'package:handol/core/router/route_paths.dart';
import 'package:handol/features/home/component/home_banner_carousel.dart';
import 'package:handol/features/home/data/home_banners.dart';
import 'package:handol/features/home/model/home_banner.dart';

void main() {
  group('BannerLink.parse: 서버 문자열 → 갈 곳', () {
    test('https 는 외부, 아는 앱 경로는 앱 화면', () {
      expect(
        BannerLink.parse('https://instagram.com/x'),
        isA<ExternalBannerLink>(),
      );
      final app = BannerLink.parse('/bus?origin=station');
      expect(app, isA<AppBannerLink>());
      expect((app! as AppBannerLink).isTab, isTrue);
      expect(
        (BannerLink.parse(RoutePaths.organization)! as AppBannerLink).isTab,
        isFalse,
      );
    });

    test('약속에 없는 값은 눌리지 않는 배너(null)', () {
      for (final raw in [
        null,
        '',
        '  ',
        'http://insecure.example',
        'javascript:alert(1)',
        'intent://x#Intent;end',
        '/unknown/hidden',
        '//evil.example/home',
        'https:///no-host',
      ]) {
        expect(BannerLink.parse(raw), isNull, reason: '$raw');
      }
    });
  });

  Future<GoRouter> pump(WidgetTester tester, List<HomeBanner> banners) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget page(String name) => Scaffold(body: Text(name));
    final router = GoRouter(
      initialLocation: RoutePaths.home,
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder:
              (_, _) => Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(33),
                  child: HomeBannerCarousel(banners: banners),
                ),
              ),
          routes: [
            GoRoute(path: 'organization', builder: (_, _) => page('ORG')),
          ],
        ),
        GoRoute(path: RoutePaths.meal, builder: (_, _) => page('MEAL')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('시안 비율 345×138, 링크 없는 광고는 눌리지 않는다', (tester) async {
    await pump(tester, const [
      HomeBanner(title: '축제', image: HandolAssets.adFestival),
    ]);
    expect(
      tester.getSize(find.byType(HomeBannerCard)),
      const Size(346, 346 * 138 / 345),
    );
    expect(find.bySemanticsLabel('광고: 축제'), findsOneWidget);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });

  testWidgets('기능 소개 카드를 누르면 탭은 바꾸고, 하위 화면은 쌓는다', (tester) async {
    final router = await pump(tester, const [
      HomeBanner(title: '학식', link: AppBannerLink(RoutePaths.meal)),
      HomeBanner(title: '연락처', link: AppBannerLink(RoutePaths.organization)),
    ]);
    await tester.tap(find.text('학식'));
    await tester.pumpAndSettle();
    expect(find.text('MEAL'), findsOneWidget);

    router.go(RoutePaths.home);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('연락처'));
    await tester.pumpAndSettle();
    expect(find.text('ORG'), findsOneWidget);
    expect(router.canPop(), isTrue);
  });

  test('홈 배너 목록의 앱 링크는 모두 열 수 있는 경로다', () {
    for (final b in homeBanners) {
      final link = b.link;
      if (link is AppBannerLink) {
        expect(BannerLink.parse(link.location), isA<AppBannerLink>());
      }
    }
  });
}
