import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { fetchOrganizationTree } from './api';
import { pinnedUnits, searchOrganizationTree, type OrganizationSearchResult, type OrganizationUnit } from './model';

export function useOrganizationTree() {
  return useQuery({ queryKey: ['organization', 'tree'], queryFn: fetchOrganizationTree, staleTime: 5 * 60_000 });
}

/** 홈 카드용. 못 불러오면 빈 목록. */
export function usePinnedOrganizationUnits(): OrganizationUnit[] {
  const { data } = useOrganizationTree();
  return useMemo(() => (data ? pinnedUnits(data) : []), [data]);
}

export function useOrganizationSearch(query: string) {
  const tree = useOrganizationTree();
  const results = useMemo<OrganizationSearchResult[]>(
    () => (tree.data ? searchOrganizationTree(tree.data, query) : []),
    [tree.data, query],
  );
  return { ...tree, results };
}
