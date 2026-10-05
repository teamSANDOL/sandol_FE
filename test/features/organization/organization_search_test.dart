import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/organization/domain/model/organization_node.dart';
import 'package:handori/features/organization/domain/model/organization_search_result.dart';
import 'package:handori/features/organization/presentation/util/contact_actions.dart';

void main() {
  final root = OrganizationGroupNode(
    name: 'Root',
    children: [
      OrganizationUnitNode(name: '대표연락처', phone: '03180411000'),
      OrganizationGroupNode(
        name: '총장실',
        children: [
          OrganizationUnitNode(name: '감사실', phone: '03180411092'),
          OrganizationUnitNode(name: '비서실', phone: '03180410141'),
        ],
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
      OrganizationUnitNode(name: '컴퓨터공학부', phone: '03180410510'),
    ],
  );

  group('searchOrganizationTree', () {
    test('부분일치로 유닛을 찾고 상위 경로를 돌려준다', () {
      final r = searchOrganizationTree(root, '감사');
      expect(r, hasLength(1));
      expect(r.first.node.name, '감사실');
      expect(r.first.path, ['총장실']);
    });

    test('그룹 이름도 결과에 포함된다', () {
      final r = searchOrganizationTree(root, '교무');
      expect(r.map((e) => e.node.name), ['교무처', '교무팀']);
      expect(r.last.path, ['대학본부', '교무처']);
    });

    test('공백/대소문자를 무시한다', () {
      expect(searchOrganizationTree(root, ' 컴퓨터 공학 '), hasLength(1));
    });

    test('숫자 검색은 전화번호에도 매칭된다', () {
      final r = searchOrganizationTree(root, '0510');
      expect(r.single.node.name, '컴퓨터공학부');
    });

    test('빈 검색어는 빈 결과', () {
      expect(searchOrganizationTree(root, '   '), isEmpty);
    });
  });

  group('ContactActions.formatPhone', () {
    test('11자리 → 3-4-4', () {
      expect(ContactActions.formatPhone('03180411092'), '031-8041-1092');
    });
    test('서울 10자리 → 2-4-4', () {
      expect(ContactActions.formatPhone('0212345678'), '02-1234-5678');
    });
    test('형식 미상은 원문 유지', () {
      expect(ContactActions.formatPhone('1588-1234'), '1588-1234');
    });
  });
}
