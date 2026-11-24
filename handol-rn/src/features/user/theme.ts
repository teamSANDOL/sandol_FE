/** 마이페이지 · 회원탈퇴 시안에서만 쓰는 색 (토큰에 없는 값을 한 곳에 모은다). */
export const userTheme = {
  /** 회원탈퇴 유의사항 회색 띠 (Figma 2196:1183) */
  noticeBand: '#EEF1F6',
  /** 토글 노브 그림자 (2196:552) */
  knobShadow: '0px 4px 4px rgba(0, 0, 0, 0.25)',
  /** 다이얼로그 배경 어둡게 (barrier black 50%) */
  scrim: 'rgba(0, 0, 0, 0.5)',
  /** 다이얼로그 위험 아이콘 바탕 (danger 8%) */
  dangerSoft: 'rgba(214, 59, 59, 0.08)',
  /** 다이얼로그 취소 버튼 바탕 */
  cancelBg: '#F2F3F5',
} as const;
