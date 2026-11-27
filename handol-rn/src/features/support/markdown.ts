import { resolveAssetUrl } from '@/core/assetUrl';
import type { PolicyBlock } from '@/features/user/policyParser';

/** 본문 그림 (BFF 업로드 그림은 /app/v1/assets/...) */
export type ImageBlock = { image: string; alt: string };
export type MarkdownBlock = PolicyBlock | ImageBlock;

const IMAGE = /!\[([^\]]*)\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)/g;

/** 굵게·기울임·코드 표시와 링크·그림 문법을 걷어 글자만 남긴다 */
function plain(s: string): string {
  return s
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/(\*\*|__|`)(.+?)\1/g, '$2')
    .replace(/\*(\S.*?)\*/g, '$1');
}

/**
 * BFF 공지·FAQ·서비스 안내의 Markdown 을 정책 문서와 같은 블록으로 (제목 · 단락 · 목록 · 그림).
 * 그림은 줄에서 빼내 그 줄 글 다음에 한 장씩 둔다. https 가 아니거나 BFF 경로가 아닌 그림은 버린다.
 * ponytail: 링크·표는 글자만 남긴다. 눌리는 링크가 필요해지면 렌더러를 붙인다.
 */
export function parseMarkdown(md: string, assetBase: string): MarkdownBlock[] {
  const blocks: MarkdownBlock[] = [];
  let para: string[] = [];
  const flush = () => {
    if (para.length) blocks.push({ isHeading: false, text: para.join(' '), marker: null, depth: 0 });
    para = [];
  };
  for (const line of md.replace(/\r/g, '').split('\n')) {
    const t = line.trim();
    if (!t) {
      flush();
      continue;
    }
    const images = [...t.matchAll(IMAGE)];
    if (images.length) {
      const rest = t.replace(IMAGE, '').trim();
      if (rest) para.push(plain(rest));
      flush();
      for (const [, alt, src] of images) {
        const url = resolveAssetUrl(src, assetBase);
        if (url) blocks.push({ image: url, alt });
      }
      continue;
    }
    const heading = /^#{1,6}\s+(.*)$/.exec(t);
    if (heading) {
      flush();
      blocks.push({ isHeading: true, text: plain(heading[1]) });
      continue;
    }
    const item = /^(?:([-*+])|(\d+)[.)])\s+(.*)$/.exec(t);
    if (item) {
      flush();
      const depth = Math.floor((line.length - line.trimStart().length) / 2) + 1;
      blocks.push({ isHeading: false, text: plain(item[3]), marker: item[1] ? '•' : `${item[2]}.`, depth });
      continue;
    }
    para.push(plain(t));
  }
  flush();
  return blocks;
}
