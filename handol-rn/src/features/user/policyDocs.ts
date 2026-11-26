import { env } from '@/core/env';

export type PolicyDocId = 'terms' | 'privacy';

/** 마이페이지에서 앱 안으로 보여 주는 정책 문서 (Flutter PolicyDocument) */
export const POLICY_DOCS: Record<PolicyDocId, { label: string; url: string }> = {
  terms: { label: '서비스 이용약관', url: env.termsOfServiceUrl },
  privacy: { label: '개인정보처리방침', url: env.privacyPolicyUrl },
};

/** 알 수 없는 값은 이용약관으로 */
export function toPolicyDocId(raw: string | string[] | undefined): PolicyDocId {
  const v = Array.isArray(raw) ? raw[0] : raw;
  return v === 'privacy' ? 'privacy' : 'terms';
}
