import 'package:handori/features/auth/domain/model/auth_session.dart';

abstract class AuthRepository {
  /// 브라우저(Keycloak 로그인 페이지)를 띄워 로그인한다.
  /// [useKakao] 가 true 면 Keycloak 화면을 건너뛰고 카카오 로그인으로 직행한다
  /// (`kc_idp_hint=kakao`). 사용자가 취소하면
  /// [FlutterAppAuthUserCancelledException] 이 던져진다.
  Future<AuthSession> login({bool useKakao = false});

  /// 저장된 세션을 복원한다. 액세스 토큰이 만료됐으면 리프레시를 시도한다.
  /// - 리프레시 토큰이 만료/폐기됐으면 세션을 지우고 null 을 반환한다.
  /// - 네트워크 문제 등 일시적 실패면 세션을 유지한 채 저장된 세션을
  ///   그대로 반환한다 (액세스 토큰은 만료 상태일 수 있다).
  Future<AuthSession?> restoreSession();

  /// API 호출에 쓸 유효한 액세스 토큰. 비로그인 상태거나 지금 당장 유효한
  /// 토큰을 구할 수 없으면(일시적 리프레시 실패) null.
  Future<String?> getValidAccessToken();

  /// 리프레시 등으로 로그인 UI 를 거치지 않고 세션이 바뀔 때 흘러나온다.
  /// 리프레시 토큰이 폐기돼 세션이 지워지면 null 이 온다.
  Stream<AuthSession?> get sessionChanges;

  /// 서버 세션을 끊고(베스트 에포트) 로컬 토큰을 지운다.
  Future<void> logout();

  /// Keycloak 계정을 영구 삭제하고 로컬 토큰을 지운다.
  /// 서버 삭제가 실패하면 로컬 세션은 유지한 채 예외를 던진다.
  Future<void> deleteAccount();
}
