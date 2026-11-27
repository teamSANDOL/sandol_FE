import { View } from 'react-native';
import { HText, spacing } from '@/design-system';
import type { PolicyBlock } from '../policyParser';

/** 번호 항목 한 단계 들여쓰기(머리표 칸) */
const MARKER_WIDTH = 24;
const BODY_LINE = 16 * 1.6;

/** 문서 본문(제목·단락·번호 항목). 정책 문서와 서비스 공지·안내가 함께 쓴다 */
export function DocBlocks({ blocks }: { blocks: readonly PolicyBlock[] }) {
  return (
    <>
      {blocks.map((b, i) => (
        <DocBlock key={i} block={b} />
      ))}
    </>
  );
}

export function DocBlock({ block }: { block: PolicyBlock }) {
  if (block.isHeading) {
    return (
      <HText variant="headline" keepAll style={{ marginTop: spacing.lg, marginBottom: 6 }}>
        {block.text}
      </HText>
    );
  }
  const body = (
    <HText variant="body" keepAll style={{ lineHeight: BODY_LINE }}>
      {block.text}
    </HText>
  );
  // 항목 안의 항목은 머리표 칸만큼 더 들어간다.
  const indent = MARKER_WIDTH * (block.depth - (block.marker === null ? 0 : 1));
  return (
    <View style={{ marginTop: 6, paddingLeft: indent }}>
      {block.marker !== null ? (
        <View style={{ flexDirection: 'row', alignItems: 'flex-start' }}>
          <View style={{ width: MARKER_WIDTH }}>
            <HText variant="body" tone="muted" style={{ lineHeight: BODY_LINE }}>
              {block.marker}
            </HText>
          </View>
          <View style={{ flex: 1 }}>{body}</View>
        </View>
      ) : (
        body
      )}
    </View>
  );
}
