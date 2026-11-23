import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:handol/core/design_system/handol_tokens.dart';
import 'package:handol/core/utils/external_link.dart';
import 'package:handol/features/home/model/home_banner.dart';
import 'package:handol/shared/widget/remote_image.dart';

/// 배너 링크를 연다.
void openBannerLink(BuildContext context, BannerLink link) {
  switch (link) {
    case ExternalBannerLink(:final uri):
      openExternalLink(context, uri.toString());
    case AppBannerLink(:final location, :final isTab):
      isTab ? context.go(location) : context.push(location);
  }
}

/// 홈 맨 위 배너 자리 (Figma 홈_re 2890:2393 의 2901:1129, 345×138).
/// 옆으로 넘겨 여러 장을 본다. 한 장뿐이면 점 표시가 없다.
class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, required this.banners});

  static const double aspectRatio = 345 / 138;

  final List<HomeBanner> banners;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(
      spacing: HandolSpacing.sm,
      children: [
        AspectRatio(
          aspectRatio: HomeBannerCarousel.aspectRatio,
          child: PageView.builder(
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => HomeBannerCard(banner: banners[i]),
          ),
        ),
        if (banners.length > 1)
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: HandolSpacing.xs,
              children: [
                for (var i = 0; i < banners.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          i == _page
                              ? HandolColors.primary
                              : HandolColors.track,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 배너 한 장. 그림 배너는 그림만, 글자 배너는 제목·설명·아이콘을 그린다.
class HomeBannerCard extends StatelessWidget {
  const HomeBannerCard({super.key, required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    final link = banner.link;
    final label = banner.isImage ? '광고: ${banner.title}' : banner.title;
    return Semantics(
      button: link != null,
      label: banner.body == null ? label : '$label, ${banner.body}',
      excludeSemantics: true,
      onTap: link == null ? null : () => openBannerLink(context, link),
      child: ClipRRect(
        borderRadius: HandolMetrics.radius,
        child: Material(
          color: HandolColors.primary,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (banner.isImage)
                RemoteImage(
                  url: banner.imageUrl,
                  asset: banner.image,
                  fit: BoxFit.cover,
                )
              else
                _TextBanner(banner: banner),
              InkWell(
                onTap:
                    link == null ? null : () => openBannerLink(context, link),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextBanner extends StatelessWidget {
  const _TextBanner({required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    final icon = banner.icon;
    final body = banner.body;
    const white = Colors.white;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: HandolGradients.primaryCard),
      child: Padding(
        padding: const EdgeInsets.all(HandolMetrics.cardInset),
        child: Row(
          spacing: HandolSpacing.md,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: HandolSpacing.xs,
                children: [
                  Text(
                    banner.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HandolTypography.title.copyWith(color: white),
                  ),
                  if (body != null)
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: HandolTypography.caption.copyWith(
                        color: white.withValues(alpha: .85),
                      ),
                    ),
                ],
              ),
            ),
            if (icon != null)
              CircleAvatar(
                radius: 26,
                backgroundColor: white.withValues(alpha: .2),
                child: SvgPicture.asset(
                  icon,
                  width: 26,
                  height: 26,
                  colorFilter: const ColorFilter.mode(white, BlendMode.srcIn),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
