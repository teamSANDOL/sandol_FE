import { useEffect, useSyncExternalStore } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { nextSeen, type Notice, type SeenMap } from './model';

/** AsyncStorage 에 JSON 으로 백업하는 작은 전역 저장소. 저장이 실패해도 메모리 상태는 유지된다. */
function createStore<T>(key: string, initial: T, revive: (raw: unknown) => T | null) {
  let value = initial;
  let loaded = false;
  const listeners = new Set<() => void>();
  const set = (next: T) => {
    value = next;
    listeners.forEach((l) => l());
  };
  return {
    get: () => value,
    subscribe: (cb: () => void) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
    async load(): Promise<void> {
      if (loaded) return;
      loaded = true;
      try {
        const raw = await AsyncStorage.getItem(key);
        const parsed = raw === null ? null : revive(JSON.parse(raw));
        // 읽는 사이 이미 바뀌었으면 덮어쓰지 않는다. 손상된 값은 첫 실행처럼 둔다.
        if (parsed !== null && value === initial) set(parsed);
      } catch {
        // 읽기 실패 · 손상된 값은 초기값으로 시작한다.
      }
    },
    async update(next: T): Promise<void> {
      set(next);
      try {
        await AsyncStorage.setItem(key, JSON.stringify(next));
      } catch {
        // 저장 실패는 조용히 넘긴다. 다음 실행에서 초기값일 뿐이다.
      }
    },
  };
}

const isNotice = (m: unknown): m is Notice =>
  typeof m === 'object' && m !== null && typeof (m as Notice).id === 'number' && typeof (m as Notice).url === 'string';

const EMPTY_BOOKMARKS: Notice[] = [];
const bookmarkStore = createStore<Notice[]>('notice.bookmarks', EMPTY_BOOKMARKS, (raw) =>
  Array.isArray(raw) ? raw.filter(isNotice) : null,
);

const seenStore = createStore<SeenMap | null>('notice.seen', null, (raw) =>
  typeof raw === 'object' && raw !== null && !Array.isArray(raw) ? (raw as SeenMap) : null,
);

function useLoaded<T>(store: { get: () => T; subscribe: (cb: () => void) => () => void; load: () => Promise<void> }): T {
  useEffect(() => {
    void store.load();
  }, [store]);
  return useSyncExternalStore(store.subscribe, store.get);
}

/** 저장한 공지(맨 앞이 가장 최근). 공지 전체를 둬서 목록 밖의 오래된 공지도 다시 그린다. */
export const useBookmarks = (): Notice[] => useLoaded(bookmarkStore);
export const useSeen = (): SeenMap | null => useLoaded(seenStore);

export const getBookmarks = (): Notice[] => bookmarkStore.get();

/** 저장돼 있으면 빼고, 없으면 맨 앞에 넣는다. */
export function toggleBookmark(notice: Notice): Promise<void> {
  const cur = bookmarkStore.get();
  return bookmarkStore.update(
    cur.some((n) => n.id === notice.id) ? cur.filter((n) => n.id !== notice.id) : [notice, ...cur],
  );
}

export async function loadBookmarks(): Promise<void> {
  await bookmarkStore.load();
}

/** 목록을 떠나며, 그때 불러와 있던 공지를 본 공지로 남긴다. */
export async function markSeen(loaded: Notice[]): Promise<void> {
  await seenStore.load();
  await seenStore.update(nextSeen(seenStore.get(), loaded));
}
