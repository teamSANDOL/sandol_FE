import { useEffect, useSyncExternalStore } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { BUILDING_SORTS, defaultSortSettings, type BuildingSort, type BuildingSortSettings } from './sort';

/** 홈 카드 정렬 설정. 기기 로컬(AsyncStorage)에 저장한다. 저장이 실패해도 메모리 상태는 유지된다. */
const MODE_KEY = 'empty_class.sort_mode';
const ORDER_KEY = 'empty_class.custom_order';

let state: BuildingSortSettings = defaultSortSettings;
let loadStarted = false;
const listeners = new Set<() => void>();

function emit(next: BuildingSortSettings): void {
  state = next;
  listeners.forEach((l) => l());
}

export function parseSettings(modeRaw: string | null, orderRaw: string | null): BuildingSortSettings {
  const mode = BUILDING_SORTS.find((m) => m === modeRaw) ?? defaultSortSettings.mode;
  let customOrder: string[] = [];
  try {
    const parsed: unknown = orderRaw ? JSON.parse(orderRaw) : [];
    if (Array.isArray(parsed)) customOrder = parsed.filter((x): x is string => typeof x === 'string');
  } catch {
    customOrder = [];
  }
  return { mode, customOrder };
}

async function load(): Promise<void> {
  if (loadStarted) return;
  loadStarted = true;
  try {
    const [mode, order] = await Promise.all([AsyncStorage.getItem(MODE_KEY), AsyncStorage.getItem(ORDER_KEY)]);
    emit(parseSettings(mode, order));
  } catch {
    // 읽기 실패는 기본값으로 둔다.
  }
}

async function save(s: BuildingSortSettings): Promise<void> {
  try {
    await Promise.all([AsyncStorage.setItem(MODE_KEY, s.mode), AsyncStorage.setItem(ORDER_KEY, JSON.stringify(s.customOrder))]);
  } catch {
    // 저장 실패는 조용히 넘긴다. 다음 실행에서 기본값으로 돌아갈 뿐이다.
  }
}

export const buildingSortActions = {
  setMode(mode: BuildingSort): void {
    if (mode === state.mode) return;
    emit({ ...state, mode });
    void save(state);
  },
  /** 전체 순서를 교체한다. 시트에서 드래그로 옮길 때 호출 */
  setCustomOrder(order: readonly string[]): void {
    emit({ ...state, customOrder: [...order] });
    void save(state);
  },
};

export function useBuildingSortSettings(): BuildingSortSettings {
  useEffect(() => {
    void load();
  }, []);
  return useSyncExternalStore(
    (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    () => state,
  );
}
