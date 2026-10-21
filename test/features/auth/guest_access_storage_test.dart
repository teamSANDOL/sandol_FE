import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handori/features/auth/data/guest_access_storage.dart';
import 'package:handori/features/auth/domain/model/auth_session.dart';
import 'package:handori/features/auth/domain/repository/auth_repository.dart';
import 'package:handori/features/auth/presentation/provider/auth_provider.dart';

class _FakeRepository extends Fake implements AuthRepository {
  @override
  Future<AuthSession> login({
    bool useKakao = false,
    bool signUp = false,
    bool rememberMe = true,
  }) async => const AuthSession(accessToken: 'test-only');

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();

  @override
  Future<void> logout() async {}
}

void main() {
  final base = DateTime.utc(2026, 10, 21, 12);
  late DateTime now;
  late GuestAccessStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    now = base;
    storage = GuestAccessStorage(const FlutterSecureStorage(), now: () => now);
  });

  test('기록이 없으면 활성이 아니다', () async {
    expect(await storage.isActive(), isFalse);
  });

  test('7일 이내면 활성, 7일이 지나면 만료', () async {
    await storage.start();
    now = base.add(GuestAccessStorage.validFor - const Duration(minutes: 1));
    expect(await storage.isActive(), isTrue);
    now = base.add(GuestAccessStorage.validFor);
    expect(await storage.isActive(), isFalse);
  });

  test('기기 시간이 과거로 돌아가 기록이 미래면 만료로 본다', () async {
    await storage.start();
    now = base.subtract(const Duration(days: 1));
    expect(await storage.isActive(), isFalse);
  });

  test('다시 시작하면 시각이 갱신된다', () async {
    await storage.start();
    now = base.add(const Duration(days: 8));
    expect(await storage.isActive(), isFalse);
    await storage.start();
    expect(await storage.isActive(), isTrue);
  });

  test('손상된 값은 만료로 본다', () async {
    FlutterSecureStorage.setMockInitialValues({
      'guest_browsing_started_at': 'garbage',
    });
    expect(await storage.isActive(), isFalse);
  });

  test('로그인에 성공하면 둘러보기 기록을 지운다', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeRepository()),
        guestAccessStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
    await storage.start();
    expect(await storage.isActive(), isTrue);

    expect(await container.read(authNotifierProvider.notifier).login(), isTrue);
    expect(await storage.isActive(), isFalse);
  });
}
