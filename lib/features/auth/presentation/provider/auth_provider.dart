import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:handori/core/constants/api_constants.dart';
import 'package:handori/features/auth/data/repository/auth_repository_impl.dart';
import 'package:handori/features/auth/data/token_storage.dart';
import 'package:handori/features/auth/domain/model/auth_session.dart';
import 'package:handori/features/auth/domain/repository/auth_repository.dart';

part 'auth_provider.g.dart';

// ── Repository ─────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    storage: TokenStorage(const FlutterSecureStorage()),
    // .env 로 오버라이드 가능 (로컬 Keycloak 테스트용). 기본은 프로덕션.
    issuer: dotenv.maybeGet('AUTH_ISSUER') ?? ApiConstants.authIssuer,
    clientId: dotenv.maybeGet('AUTH_CLIENT_ID') ?? ApiConstants.authClientId,
    redirectUri: ApiConstants.authRedirectUri,
  );
}

// ── 세션 상태 ────────────────────────────────────────────────────────────────
// AsyncData(null) = 비로그인, AsyncData(session) = 로그인됨.

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthSession?> build() {
    final repository = ref.watch(authRepositoryProvider);
    // API 인터셉터가 백그라운드에서 리프레시하다 세션을 갱신/폐기하면
    // 화면 상태도 같이 따라간다 (로그인 표시인데 토큰이 없는 불일치 방지).
    final subscription = repository.sessionChanges.listen((session) {
      // 로그인 브라우저가 열려 있는 동안(AsyncLoading) 백그라운드 리프레시
      // 결과가 버튼을 다시 살리지 않게 한다. 로그인이 끝나면 그쪽이 상태를
      // 확정한다.
      if (state.isLoading) return;
      state = AsyncData(session);
    });
    ref.onDispose(subscription.cancel);
    return repository.restoreSession();
  }

  /// 앱이 포그라운드로 돌아오는 등 세션을 미리 점검할 시점에 호출한다.
  /// 액세스 토큰이 만료됐으면 지금 갱신하고, 리프레시 토큰까지 만료됐으면
  /// 비로그인 상태로 전환한다. 로그인 진행 중이면 건드리지 않는다.
  Future<void> refreshIfNeeded() async {
    if (state.isLoading) return;
    // 비로그인 상태여도 다시 읽는다. 시작 시 보안 저장소가 잠겨 있어(첫 잠금
    // 해제 전 실행 등) 세션을 못 읽었다면 복귀 시점에 되살아난다. 게스트에게는
    // 저장소 읽기 한 번의 비용이다.
    // 기다리는 동안 로그아웃·재로그인이 끝났어도 저장소가 세대 검사로
    // "지금의 진실"을 돌려주므로 그대로 반영해도 안전하다.
    final session = await ref.read(authRepositoryProvider).restoreSession();
    if (state.isLoading) return;
    state = AsyncData(session);
  }

  /// 로그인 성공 시 true. 사용자가 브라우저를 닫는 등 취소하면 이전 상태를
  /// 유지하고 false, 그 외 실패는 AsyncError 상태로 두고 false 를 반환한다.
  Future<bool> login({bool useKakao = false}) async {
    final previous = state;
    state = const AsyncLoading();
    try {
      final session =
          await ref.read(authRepositoryProvider).login(useKakao: useKakao);
      state = AsyncData(session);
      return true;
    } on FlutterAppAuthUserCancelledException {
      state = previous;
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// Keycloak 계정을 영구 삭제한다. 서버 삭제 실패 시 예외가 그대로 올라오며
  /// 세션 상태는 유지된다 — 호출부(UI)에서 안내한다.
  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
    state = const AsyncData(null);
  }
}
