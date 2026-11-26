import { useState } from 'react';
import { HPressable, Icon, colors } from '@/design-system';
import { BuildingSortSheet } from './BuildingSortSheet';

/** 홈 빈 강의실 섹션 제목 오른쪽 '정렬 설정' 아이콘 버튼 + 정렬 시트. 계약: props 없음 */
export function BuildingSortButton() {
  const [open, setOpen] = useState(false);
  return (
    <>
      <HPressable
        accessibilityRole="button"
        accessibilityLabel="정렬 설정"
        hitSlop={12}
        borderless
        onPress={() => setOpen(true)}
      >
        <Icon name="emptyClassSetting" size={18} color={colors.muted} />
      </HPressable>
      <BuildingSortSheet visible={open} onClose={() => setOpen(false)} />
    </>
  );
}
