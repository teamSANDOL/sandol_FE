import { useQuery } from '@tanstack/react-query';
import { POLICY_DOCS, type PolicyDocId } from './policyDocs';
import { parsePolicyHtml, type PolicyContent } from './policyParser';

const TIMEOUT_MS = 15_000;

/** 인증 헤더가 붙는 앱 API 클라이언트가 아니라 빈 fetch 로 받는다. */
async function fetchPolicy(doc: PolicyDocId): Promise<PolicyContent> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(POLICY_DOCS[doc].url, { signal: controller.signal });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return parsePolicyHtml(await res.text());
  } finally {
    clearTimeout(timer);
  }
}

export function usePolicy(doc: PolicyDocId) {
  return useQuery({ queryKey: ['user', 'policy', doc], queryFn: () => fetchPolicy(doc), staleTime: 0, gcTime: 0 });
}
