import 'package:handol/core/router/route_paths.dart';

/// 홈 맨 위 배너 한 장. 광고(글자까지 그린 그림)와 기능 소개(글자 카드)가 같은
/// 자리를 넘겨 가며 쓴다. 필드는 BFF 응답(docs/BFF_APP_CONTENT.md)과 같다.
class HomeBanner {
  const HomeBanner({
    required this.title,
    this.body,
    this.image,
    this.imageUrl,
    this.icon,
    this.link,
  });

  /// 글자 카드의 제목. 그림 카드에선 화면 읽기용 광고 내용.
  final String title;
  final String? body;

  /// 앱 내장 그림. [imageUrl] 을 못 받을 때도 이 그림을 보여 준다.
  final String? image;

  /// 서버 그림. 있으면 [image] 보다 먼저.
  final String? imageUrl;

  /// 글자 카드 오른쪽 아이콘(SVG 에셋)
  final String? icon;

  /// 누르면 갈 곳. null 이면 눌리지 않는다.
  final BannerLink? link;

  bool get isImage => image != null || imageUrl != null;
}

/// 배너를 눌렀을 때 갈 곳.
///
/// 서버는 문자열 하나로 준다: `https://...` 는 외부 브라우저, `/...` 는 앱 화면.
/// 앱 화면은 [appRoutes] 에 있는 경로만 연다. 메뉴에 없는 숨은 화면도 라우터와
/// 이 목록에 넣으면 배너로만 들어가게 할 수 있다.
sealed class BannerLink {
  const BannerLink();

  /// 약속에 맞지 않는 값(http, 다른 스킴, 모르는 경로)은 null — 눌리지 않는 배너.
  static BannerLink? parse(String? raw) {
    final uri = Uri.tryParse(raw?.trim() ?? '');
    if (uri == null || uri.toString().isEmpty) return null;
    if (uri.scheme == 'https' && uri.host.isNotEmpty) {
      return ExternalBannerLink(uri);
    }
    if (!uri.hasScheme && !uri.hasAuthority && appRoutes.contains(uri.path)) {
      return AppBannerLink(uri.toString());
    }
    return null;
  }
}

/// 외부 브라우저로 여는 링크 (학생회 인스타 등)
final class ExternalBannerLink extends BannerLink {
  const ExternalBannerLink(this.uri);
  final Uri uri;
}

/// 앱 안 화면 (쿼리 포함 가능)
final class AppBannerLink extends BannerLink {
  const AppBannerLink(this.location);
  final String location;

  /// 탭 루트면 탭을 바꾸고(go), 하위 화면이면 위에 쌓는다(push).
  bool get isTab => tabRoutes.contains(Uri.parse(location).path);
}

/// 하단 탭 루트
const tabRoutes = {
  RoutePaths.home,
  RoutePaths.meal,
  RoutePaths.bus,
  RoutePaths.notice,
  RoutePaths.map,
};

/// 배너로 열 수 있는 앱 화면. 인자(extra)가 꼭 필요한 화면은 넣지 않는다.
const appRoutes = {...tabRoutes, RoutePaths.organization, RoutePaths.user};
