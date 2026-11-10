import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handori/core/constants/api_constants.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

/// 마이페이지에서 앱 안으로 보여 주는 정책 문서.
///
/// 정책 원문은 quanect.kr 웹 페이지 하나뿐이라(별도 JSON API 없음) 그 HTML을
/// 받아 제목·조항·번호 항목만 뽑아 앱 화면으로 다시 그린다. 웹에서 문서를
/// 고치면 앱도 따라 바뀐다.
enum PolicyDocument {
  terms('서비스 이용약관', ApiConstants.termsOfServiceUrl),
  privacy('개인정보처리방침', ApiConstants.privacyPolicyUrl);

  const PolicyDocument(this.label, this.url);

  final String label;
  final String url;
}

/// 조항 제목(`제1조(목적)`) 또는 본문 한 단락.
class PolicyBlock {
  const PolicyBlock.heading(this.text)
    : isHeading = true,
      marker = null,
      depth = 0;
  const PolicyBlock.paragraph(this.text, {this.marker, this.depth = 0})
    : isHeading = false;

  final bool isHeading;
  final String text;

  /// 번호 항목의 `1.`, `가.` 같은 머리표. 항목의 첫 단락에만 붙는다.
  final String? marker;

  /// 번호 항목 안에 들어간 깊이. 0이면 조항 바로 아래 단락이다.
  final int depth;
}

class PolicyContent {
  const PolicyContent({required this.intro, required this.blocks});

  /// 문서 맨 위 한 줄 설명
  final String? intro;
  final List<PolicyBlock> blocks;
}

/// quanect.kr 정책 페이지 HTML에서 본문을 뽑는다.
///
/// 구조: `main > header(h1, p)` 다음에 조항마다 `section > h2 + p…`, 번호 항목은
/// `div.flex.gap-3 > span(머리표) + div(p…)` 이고 항목 안에 항목이 다시 들어간다.
PolicyContent parsePolicyHtml(String source) {
  final main = html.parse(source).querySelector('main');
  final blocks = <PolicyBlock>[];
  for (final el
      in main?.querySelectorAll('section h2, section p') ?? <Element>[]) {
    final text = el.text.trim();
    if (text.isEmpty) continue;
    if (el.localName == 'h2') {
      blocks.add(PolicyBlock.heading(text));
      continue;
    }
    final items = _ancestors(el).where(_isListItem).toList();
    final item = items.firstOrNull;
    blocks.add(
      PolicyBlock.paragraph(
        text,
        depth: items.length,
        // 항목의 첫 단락에만 머리표를 붙인다.
        marker:
            item != null && item.querySelector('p') == el
                ? item.children.first.text.trim()
                : null,
      ),
    );
  }
  if (blocks.isEmpty) throw const FormatException('정책 본문을 찾지 못했습니다');
  final intro = main?.querySelector('header p')?.text.trim();
  return PolicyContent(intro: intro, blocks: blocks);
}

Iterable<Element> _ancestors(Element el) sync* {
  for (var p = el.parent; p != null; p = p.parent) {
    yield p;
  }
}

bool _isListItem(Element el) =>
    el.localName == 'div' &&
    el.classes.contains('flex') &&
    el.children.length == 2 &&
    el.children.first.localName == 'span';

final policyProvider = FutureProvider.autoDispose
    .family<PolicyContent, PolicyDocument>((ref, doc) async {
      // 인증 헤더가 붙는 앱 API 클라이언트가 아니라 빈 클라이언트로 받는다.
      final res = await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          responseType: ResponseType.plain,
        ),
      ).get<String>(doc.url);
      return parsePolicyHtml(res.data ?? '');
    });
