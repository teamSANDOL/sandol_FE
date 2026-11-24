import { parsePolicyHtml } from '../policyParser';

const html = `<!doctype html><html><head><style>.a{}</style><script>var x="<p>no</p>"</script></head><body>
<main><header><h1>이용약관</h1><p>한돌이 &amp; 약관</p></header>
<section><h2>제1조(목적)</h2><p>본 약관은 목적을 정한다.</p>
<div class="flex gap-3"><span>1.</span><div><p>첫째 항목</p><p>둘째 단락</p>
<div class="flex gap-3"><span>가.</span><div><p>하위 항목</p></div></div></div></div>
</section>
<section><h2>제2조</h2><p><!-- -->정의<br/>끝</p></section>
</main><p>main 밖</p></body></html>`;

describe('parsePolicyHtml', () => {
  const r = parsePolicyHtml(html);
  it('intro 와 제목 · 단락을 뽑고 스크립트는 무시한다', () => {
    expect(r.intro).toBe('한돌이 & 약관');
    expect(r.blocks.map((b) => b.text)).toEqual(['제1조(목적)', '본 약관은 목적을 정한다.', '첫째 항목', '둘째 단락', '하위 항목', '제2조', '정의끝']);
  });
  it('번호 항목의 머리표는 첫 단락에만, 깊이는 항목 중첩 수', () => {
    const p = r.blocks.filter((b) => !b.isHeading) as Extract<(typeof r.blocks)[number], { isHeading: false }>[];
    expect(p.map((b) => [b.marker, b.depth])).toEqual([
      [null, 0],
      ['1.', 1],
      [null, 1],
      ['가.', 2],
      [null, 0],
    ]);
  });
  it('본문이 없으면 오류', () => expect(() => parsePolicyHtml('<main></main>')).toThrow());
});
