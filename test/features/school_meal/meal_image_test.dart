import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/core/design_system/sandol_assets.dart';
import 'package:handori/features/school_meal/data/dto/meal_response.dart';
import 'package:handori/features/school_meal/data/dto/restaurant_response.dart';
import 'package:handori/features/school_meal/domain/model/meal.dart';
import 'package:handori/features/school_meal/domain/model/meal_type.dart';
import 'package:handori/features/school_meal/domain/model/restaurant.dart';
import 'package:handori/features/school_meal/presentation/model/restaurant_menu.dart';
import 'package:handori/shared/widget/remote_image.dart';

Map<String, Object?> _restaurantJson({Object? imageUrl}) => {
  'id': 1,
  'name': 'TIP 가가식당',
  'establishment_type': 'student',
  'image_url': imageUrl,
};

Meal _meal({String? imageUrl}) => Meal(
  id: 1,
  restaurantId: 1,
  mealType: MealType.lunch,
  menu: const ['김치찌개'],
  restaurantName: 'TIP 가가식당',
  registeredAt: DateTime(2026, 10, 6),
  updatedAt: DateTime(2026, 10, 6),
  imageUrl: imageUrl,
);

MenuSlot? _lunch(RestaurantMenu m) =>
    m.slots.where((s) => s.mealType == MealType.lunch).firstOrNull;

void main() {
  group('image_url 해석', () {
    test('없거나 빈 값이면 null', () {
      expect(
        RestaurantResponse.fromJson(_restaurantJson()).toDomain().imageUrl,
        isNull,
      );
      expect(
        RestaurantResponse.fromJson(
          _restaurantJson(imageUrl: ''),
        ).toDomain().imageUrl,
        isNull,
      );
    });

    test('경로만 오면 학식 서버 기준 절대 주소로 푼다', () {
      expect(
        RestaurantResponse.fromJson(
          _restaurantJson(imageUrl: '/meal/images/1.jpg'),
        ).toDomain().imageUrl,
        'https://sandori.kr/meal/images/1.jpg',
      );
    });

    test('절대 주소는 그대로 둔다', () {
      final meal =
          MealResponse.fromJson({
            'id': 1,
            'menu': ['김치찌개'],
            'meal_type': 'lunch',
            'registered_at': '2026-10-06T00:00:00',
            'restaurant_id': 1,
            'restaurant_name': 'TIP 가가식당',
            'updated_at': '2026-10-06T00:00:00',
            'image_url': 'https://cdn.example.com/m.jpg',
          }).toDomain();
      expect(meal.imageUrl, 'https://cdn.example.com/m.jpg');
    });
  });

  group('photoUrlFor', () {
    const plain = Restaurant(id: 1, name: 'TIP 가가식당', establishmentType: '');
    const withPhoto = Restaurant(
      id: 1,
      name: 'TIP 가가식당',
      establishmentType: '',
      imageUrl: 'https://x/r.jpg',
    );

    test('서버 사진이 없으면 null, 에셋은 그대로', () {
      final m = buildRestaurantMenus([plain], [_meal()]).single;
      expect(m.photoUrlFor(_lunch(m)), isNull);
      expect(m.photoAsset, SandolAssets.mealGaga);
    });

    test('식당 사진만 있으면 식당 사진', () {
      final m = buildRestaurantMenus([withPhoto], [_meal()]).single;
      expect(m.photoUrlFor(_lunch(m)), 'https://x/r.jpg');
    });

    test('메뉴 사진이 있으면 식당 사진보다 먼저', () {
      final m =
          buildRestaurantMenus(
            [withPhoto],
            [_meal(imageUrl: 'https://x/m.jpg')],
          ).single;
      expect(m.photoUrlFor(_lunch(m)), 'https://x/m.jpg');
    });
  });

  group('RemoteImage', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(home: SizedBox(width: 100, height: 100, child: child)),
    );

    testWidgets('주소가 없으면 에셋', (tester) async {
      await pump(tester, const RemoteImage(asset: SandolAssets.mealGaga));
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
    });

    testWidgets('주소도 에셋도 없으면 자리표시', (tester) async {
      await pump(tester, const RemoteImage(placeholder: Text('자리표시')));
      expect(find.byType(Image), findsNothing);
      expect(find.text('자리표시'), findsOneWidget);
    });

    testWidgets('주소가 있으면 서버 이미지를 쓰고, 실패하면 에셋으로', (tester) async {
      await pump(
        tester,
        const RemoteImage(
          url: 'https://example.com/m.jpg',
          asset: SandolAssets.mealGaga,
        ),
      );
      final network = tester.widget<Image>(find.byType(Image).first);
      expect(network.image, isA<NetworkImage>());
      // 테스트 환경의 HTTP 는 항상 실패(400)하므로 에셋으로 대체된다.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      expect(
        tester.widgetList<Image>(find.byType(Image)).map((i) => i.image),
        contains(isA<AssetImage>()),
      );
    });
  });
}
