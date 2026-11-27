import { parseMarkdown } from '../markdown';

const B = 'https://bff.kr';

describe('parseMarkdown', () => {
  it('제목 · 단락 · 목록을 나눈다', () => {
    expect(parseMarkdown('# 안내\n\n이 서버는 **테스트용**입니다.\n줄 이어짐\n\n- 하나\n  - 둘\n1. 셋', B)).toEqual([
      { isHeading: true, text: '안내' },
      { isHeading: false, text: '이 서버는 테스트용입니다. 줄 이어짐', marker: null, depth: 0 },
      { isHeading: false, text: '하나', marker: '•', depth: 1 },
      { isHeading: false, text: '둘', marker: '•', depth: 2 },
      { isHeading: false, text: '셋', marker: '1.', depth: 1 },
    ]);
  });
  it('링크는 글자만, 그림은 글 다음 블록으로', () => {
    expect(parseMarkdown('[학생회](https://a.kr) 안내 ![포스터](/app/v1/assets/p.png)\n![x](http://bad.kr/a.png)', B)).toEqual([
      { isHeading: false, text: '학생회 안내', marker: null, depth: 0 },
      { image: 'https://bff.kr/app/v1/assets/p.png', alt: '포스터' },
    ]);
  });
});
