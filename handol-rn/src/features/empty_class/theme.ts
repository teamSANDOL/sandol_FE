/** 빈 강의실 화면에서만 쓰는 색 (공용 토큰에 없는 값) */
export const emptyClassTheme = {
  black87: 'rgba(0,0,0,0.87)',
  black45: 'rgba(0,0,0,0.45)',
  /** 바텀시트 손잡이 (Colors.grey.shade300) */
  sheetHandle: '#E0E0E0',
  /** 선택 안 된 라디오 */
  radioOff: '#CCD3DA',
  scrim: 'rgba(0,0,0,0.54)',
  /** 날짜 칸 바탕: track 50% */
  trackSoft: 'rgba(226,226,226,0.5)',
  /** 슬라이더 손잡이 그림자 */
  thumbShadow: '0px 1px 3px rgba(0,0,0,0.2)',
} as const;
