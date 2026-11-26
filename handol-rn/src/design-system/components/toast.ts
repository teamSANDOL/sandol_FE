/**
 * 화면 안 스낵바 (Flutter floating SnackBar 대응). 양 플랫폼이 같은 모양으로 ToastHost 에 그린다.
 * 자리는 하나뿐이라 새 안내가 기존 안내를 바로 바꾼다(hideCurrentSnackBar + showSnackBar).
 */

/** 기본 1초 (Flutter coming_soon_snackbar) */
export const TOAST_SHORT_MS = 1000;
/** Flutter SnackBar 기본 4초 */
export const TOAST_LONG_MS = 4000;

export type ToastItem = { id: number; message: string; durationMs: number };

let current: ToastItem | null = null;
let lastId = 0;
const listeners = new Set<() => void>();
const emit = () => listeners.forEach((l) => l());

export function subscribeToast(listener: () => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function getToast(): ToastItem | null {
  return current;
}

/** 짧은 안내를 띄운다. durationMs 동안 보이고 사라진다 */
export function showToast(message: string, durationMs: number = TOAST_SHORT_MS): void {
  lastId += 1;
  current = { id: lastId, message, durationMs };
  emit();
}

/** 지금 떠 있는 안내가 id 일 때만 내린다(그새 다른 안내로 바뀌었으면 그대로 둔다) */
export function hideToast(id: number): void {
  if (current?.id !== id) return;
  current = null;
  emit();
}

/** 아직 구현되지 않은 기능을 눌렀을 때 */
export function showComingSoon(): void {
  showToast('준비중입니다', TOAST_SHORT_MS);
}
