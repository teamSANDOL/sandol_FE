/** 마커 말풍선 크기. 네이티브가 자식 뷰를 비트맵으로 만들 때 폭 · 높이를 미리 알아야 한다. */
export function estimateTextWidth(text: string, fontSize: number, bold = false): number {
  let w = 0;
  for (const ch of text) {
    const cp = ch.codePointAt(0) ?? 0;
    if (cp >= 0xac00 && cp <= 0xd7a3) w += 0.96;
    else if (cp === 0x20) w += 0.28;
    else if (cp >= 0x30 && cp <= 0x39) w += 0.6;
    else if (cp >= 0x41 && cp <= 0x5a) w += 0.68;
    else w += 0.55;
  }
  return Math.ceil(w * fontSize * (bold ? 1.04 : 1)) + 2;
}

export const BUBBLE = {
  padH: 12,
  padV: 8,
  gap: 2,
  tipH: 9,
  tipHalfW: 8,
  /** 그림자가 잘리지 않게 사방에 두는 여백 */
  margin: 16,
  nameSize: 15,
  subSize: 12,
  /** 꼬리는 둥근 모서리(12) 안쪽에 남도록 가장자리에서 띄운다 */
  tipInset: 20,
  nameLine: 17,
  subLine: 14,
} as const;

export interface BubbleLayout {
  cardW: number;
  cardH: number;
  width: number;
  height: number;
  tipX: number;
  anchor: { x: number; y: number };
}

export function bubbleLayout(name: string, emptyCount: number, tipRight: boolean): BubbleLayout {
  const { padH, padV, gap, tipH, margin: m, nameSize, subSize, tipInset, nameLine, subLine } = BUBBLE;
  const nameW = estimateTextWidth(name, nameSize, true);
  const subW = estimateTextWidth(`빈 강의실 ${emptyCount}개`, subSize);
  const cardW = Math.max(nameW, subW) + padH * 2;
  const cardH = nameLine + gap + subLine + padV * 2;
  const width = cardW + m * 2;
  const height = cardH + tipH + m * 2;
  const tipX = tipRight ? m + cardW - tipInset : m + cardW / 2;
  return { cardW, cardH, width, height, tipX, anchor: { x: tipX / width, y: (m + cardH + tipH) / height } };
}
