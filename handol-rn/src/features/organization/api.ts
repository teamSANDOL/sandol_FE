import { api } from '@/core/api/client';
import { parseOrganizationTree, type OrganizationGroup } from './model';

/** GET /static-info/organization/tree */
export async function fetchOrganizationTree(): Promise<OrganizationGroup> {
  return parseOrganizationTree(await api.get<unknown>('/static-info/organization/tree'));
}
