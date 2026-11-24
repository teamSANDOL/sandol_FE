const WORD_JOINER = '\u2060';

/** 공백이 아니고, 이모지 결합(ZWJ·변형 선택자)이나 이미 있는 WJ 가 아닌 문자 */
function joinable(cp: number): boolean {
  return (
    cp > 0x20 &&
    !(cp >= 0x7f && cp <= 0xa0) &&
    cp !== 0x2060 &&
    cp !== 0x200d &&
    cp !== 0xfe0f &&
    cp !== 0x3000 &&
    !(cp >= 0x2000 && cp <= 0x200b)
  );
}

/**
 * 한글 문구를 어절(띄어쓰기) 단위로만 줄바꿈하게 한다(CSS word-break: keep-all).
 * Android 는 한글을 글자 단위로 끊으므로 같은 어절 안 글자 사이에 WORD JOINER 를 끼운다.
 * 표시 직전에만 쓴다. 검색·비교·저장할 원문에는 쓰지 않는다.
 */
export function keepAll(text: string): string {
  let out = '';
  let prev: number | undefined;
  for (const ch of text) {
    const cp = ch.codePointAt(0) ?? 0;
    if (prev !== undefined && joinable(prev) && joinable(cp)) out += WORD_JOINER;
    out += ch;
    prev = cp;
  }
  return out;
}

const ZERO_WIDTH_SPACE = '\u200B';
const isHangul = (cp: number) => (cp >= 0xac00 && cp <= 0xd7a3) || (cp >= 0x1100 && cp <= 0x11ff) || (cp >= 0x3130 && cp <= 0x318f);

/**
 * Flutter 처럼 한글 음절 사이 어디서든 줄을 바꿀 수 있게 한다.
 * Android 는 한글을 어절 단위로 끊어 Flutter 화면보다 일찍 줄이 넘어가므로 음절 사이에 폭 0 공백을 끼운다.
 * HText 가 keepAll 이 아닐 때 기본으로 쓴다.
 */
export function breakHangul(text: string): string {
  let out = '';
  let prev: number | undefined;
  for (const ch of text) {
    const cp = ch.codePointAt(0) ?? 0;
    if (prev !== undefined && isHangul(prev) && isHangul(cp)) out += ZERO_WIDTH_SPACE;
    out += ch;
    prev = cp;
  }
  return out;
}
