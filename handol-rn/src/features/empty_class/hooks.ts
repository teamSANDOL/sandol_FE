import { useMemo } from 'react';
import { keepPreviousData, useQuery, useQueryClient } from '@tanstack/react-query';
import { useUserLocation } from '@/core/location/userLocation';
import { fetchEmptyClasses } from './api';
import type { EmptyClass } from './model';
import { dayName, formatMinutes } from './query';
import { useClassroomQuery } from './queryStore';
import { sortNearby, type NearbyEmptyClass } from './sort';
import { useBuildingSortSettings } from './sortStore';

const KEY = 'emptyClasses';

/** 빈 강의실 목록 (조회 구간에 따라 갱신). 구간이 바뀌어 다시 불러오는 동안 이전 값을 유지한다. */
export function useEmptyClasses() {
  const q = useClassroomQuery();
  const key = [KEY, dayName(q), formatMinutes(q.startMinutes), formatMinutes(q.endMinutes)];
  return useQuery<EmptyClass[]>({
    queryKey: key,
    queryFn: () => fetchEmptyClasses(q),
    placeholderData: keepPreviousData,
  });
}

export function useRetryEmptyClasses(): () => void {
  const qc = useQueryClient();
  return () => void qc.invalidateQueries({ queryKey: [KEY] });
}

/** 홈 카드: 정렬 설정에 따라 정렬된 건물 + 내 위치 거리. 위치를 잡을 때까지 기다린다(최대 8초). */
export function useNearbyEmptyClasses() {
  const classes = useEmptyClasses();
  const position = useUserLocation();
  const settings = useBuildingSortSettings();
  const locating = position.isPending;
  const items = useMemo<NearbyEmptyClass[] | undefined>(
    () => (classes.data && !locating ? sortNearby(classes.data, position.data ?? null, settings) : undefined),
    [classes.data, locating, position.data, settings],
  );
  return {
    items,
    isLoading: items === undefined && !classes.isError,
    isError: classes.isError && items === undefined,
    /** 구간을 바꿔 다시 불러오는 중 (이전 값은 흐리게 보인다) */
    isRefreshing: classes.isPlaceholderData || (classes.isFetching && items !== undefined),
  };
}
