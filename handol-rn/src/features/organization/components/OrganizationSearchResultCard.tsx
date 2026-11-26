import { View } from 'react-native';
import { HText } from '@/design-system';
import type { OrganizationSearchResult } from '../model';
import { OrganizationNodeCard } from './OrganizationNodeCard';

/** 검색 결과 한 건: 상위 경로(브레드크럼) + 노드. 경로를 이미 보여주므로 depth 1 로 그린다. */
export function OrganizationSearchResultCard({ result }: { result: OrganizationSearchResult }) {
  return (
    <View>
      {result.path.length > 0 && (
        <HText variant="caption" tone="muted" numberOfLines={1}>
          {result.path.join(' › ')}
        </HText>
      )}
      <OrganizationNodeCard node={result.node} depth={1} />
    </View>
  );
}
