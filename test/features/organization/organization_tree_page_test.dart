import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/organization/domain/model/organization_node.dart';
import 'package:handori/features/organization/presentation/page/organization_tree_page.dart';
import 'package:handori/features/organization/presentation/provider/organization_provider.dart';
import 'package:handori/features/organization/presentation/widget/organization_node_card.dart';

class _Tree extends OrganizationTreeNotifier {
  _Tree(this.root);
  final OrganizationGroupNode root;
  @override
  Future<OrganizationGroupNode> build() async => root;
}

void main() {
  final root = OrganizationGroupNode(
    name: 'Root',
    children: [
      OrganizationUnitNode(
        name: '대표연락처',
        phone: '03180411000',
        url: 'https://tukorea.ac.kr/',
      ),
      OrganizationGroupNode(
        name: '대학본부',
        children: [
          OrganizationGroupNode(
            name: '교무처',
            children: [OrganizationUnitNode(name: '교무팀', phone: '03180410013')],
          ),
        ],
      ),
      OrganizationGroupNode(name: '부속기관', children: []),
    ],
  );

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizationTreeNotifierProvider.overrideWith(() => _Tree(root)),
        ],
        child: const MaterialApp(home: OrganizationTreePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('대표연락처는 강조 헤더, 그룹은 접힌 줄', (tester) async {
    await pump(tester);
    expect(find.text('대표연락처'), findsOneWidget);
    expect(find.text('031-8041-1000'), findsOneWidget);
    expect(find.text('https://tukorea.ac.kr/'), findsOneWidget);
    expect(find.text('대학본부'), findsOneWidget);
    expect(find.text('교무처'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('그룹을 누르면 하위가 들여쓰기로 펼쳐진다', (tester) async {
    await pump(tester);
    await tester.tap(find.text('대학본부'));
    await tester.pumpAndSettle();
    expect(find.text('교무처'), findsOneWidget);
    await tester.tap(find.text('교무처'));
    await tester.pumpAndSettle();
    expect(find.text('교무팀'), findsOneWidget);
    expect(find.text('031-8041-0013'), findsOneWidget);
    // 한 단계마다 28씩 들여쓴다 (부서 줄은 폴더 아이콘이 없어 그만큼 왼쪽)
    expect(
      tester.getTopLeft(find.text('교무팀')).dx,
      tester.getTopLeft(find.text('대학본부')).dx + OrganizationNodeCard.indent,
    );
  });

  testWidgets('검색어를 입력하면 부분일치 결과와 경로를 보여준다', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), '교무');
    await tester.pumpAndSettle();
    expect(find.text('부속기관'), findsNothing);
    expect(find.text('교무처'), findsOneWidget);
    expect(find.text('대학본부'), findsOneWidget); // 교무처의 경로
    expect(find.text('교무팀'), findsOneWidget);
    expect(find.text('대학본부 › 교무처'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '없는이름');
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
  });
}
