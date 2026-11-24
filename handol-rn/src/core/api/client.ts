import { env } from '../env';

/** 요청 실패. status 가 없으면 네트워크 · 타임아웃 오류다. */
export class ApiError extends Error {
  readonly status?: number;
  readonly body?: unknown;
  readonly isNetworkError: boolean;

  constructor(message: string, opts: { status?: number; body?: unknown; isNetworkError?: boolean } = {}) {
    super(message);
    this.name = 'ApiError';
    this.status = opts.status;
    this.body = opts.body;
    this.isNetworkError = opts.isNetworkError ?? false;
  }
}

type TokenGetter = () => Promise<string | null>;
let getAccessToken: TokenGetter = async () => null;

/** 인증 모듈이 시작할 때 등록한다. 토큰 조회 실패는 공개 API 를 막지 않는다. */
export function setAccessTokenGetter(getter: TokenGetter): void {
  getAccessToken = getter;
}

export type QueryValue = string | number | boolean | null | undefined;

export type RequestOptions = {
  method?: 'GET' | 'HEAD' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  query?: Record<string, QueryValue | QueryValue[]>;
  body?: unknown;
  headers?: Record<string, string>;
  /** false 면 Authorization 을 붙이지 않는다 */
  auth?: boolean;
  timeoutMs?: number;
  signal?: AbortSignal;
};

const DEFAULT_TIMEOUT_MS = 10_000;
const RETRYABLE_STATUSES = new Set([404, 502, 503, 504]);

/** 상대 주소를 base 기준 절대 주소로 (RN URL 폴리필 대신 문자열로) */
export function resolveUrl(url: string, base: string): string {
  if (/^[a-z][a-z0-9+.-]*:/i.test(url)) return url;
  if (url.startsWith('//')) return 'https:' + url;
  const origin = base.match(/^[a-z]+:\/\/[^/]+/i)?.[0] ?? base;
  if (url.startsWith('/')) return origin + url;
  const dir = base.slice(origin.length).replace(/[^/]*$/, '') || '/';
  return origin + dir + url;
}

/**
 * base + path + 쿼리. RN 의 URL 폴리필은 일부 setter 가 없어 문자열로 조립한다.
 * path 가 절대 주소면 base 를 무시한다.
 */
export function buildUrl(base: string, path: string, query?: RequestOptions['query']): string {
  const head = /^https?:\/\//i.test(path) ? path : base.replace(/\/+$/, '') + '/' + path.replace(/^\/+/, '');
  const parts: string[] = [];
  for (const [key, raw] of Object.entries(query ?? {})) {
    const values = Array.isArray(raw) ? raw : [raw];
    for (const v of values) {
      if (v !== undefined && v !== null) parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(v))}`);
    }
  }
  if (parts.length === 0) return head;
  return head + (head.includes('?') ? '&' : '?') + parts.join('&');
}

async function send(url: string, init: RequestInit, timeoutMs: number, signal?: AbortSignal): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  const onAbort = () => controller.abort();
  signal?.addEventListener('abort', onAbort);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } catch (e) {
    // 호출자가 취소한 요청은 네트워크 오류가 아니다(대체 서버로 재시도하지 않는다).
    if (signal?.aborted) throw e;
    throw new ApiError(e instanceof Error ? e.message : '네트워크 오류', { isNetworkError: true });
  } finally {
    clearTimeout(timer);
    signal?.removeEventListener('abort', onAbort);
  }
}

async function parse(res: Response): Promise<unknown> {
  const text = await res.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

/**
 * 공용 HTTP 클라이언트 (Dio + AuthInterceptor + FallbackInterceptor 대응).
 * GET · HEAD 가 404 · 502 · 503 · 504 · 네트워크 오류면 대체 서버로 인증 헤더 없이 1회 재시도한다.
 */
export async function apiRequest<T>(path: string, opts: RequestOptions = {}): Promise<T> {
  const method = opts.method ?? 'GET';
  const headers: Record<string, string> = { Accept: 'application/json', ...opts.headers };
  if (opts.body !== undefined) headers['Content-Type'] ??= 'application/json';
  if (opts.auth !== false) {
    try {
      const token = await getAccessToken();
      if (token) headers.Authorization = `Bearer ${token}`;
    } catch {
      // 토큰 조회 실패가 공개 API 호출까지 막아서는 안 된다.
    }
  }
  const body =
    opts.body === undefined
      ? undefined
      : headers['Content-Type'] === 'application/json'
        ? JSON.stringify(opts.body)
        : (opts.body as BodyInit);
  const timeout = opts.timeoutMs ?? DEFAULT_TIMEOUT_MS;

  let failure: ApiError;
  try {
    const res = await send(buildUrl(env.apiBaseUrl, path, opts.query), { method, headers, body }, timeout, opts.signal);
    const data = await parse(res);
    if (res.ok) return data as T;
    failure = new ApiError(`HTTP ${res.status}`, { status: res.status, body: data });
  } catch (e) {
    if (!(e instanceof ApiError)) throw e;
    failure = e;
  }

  const canRetry =
    env.apiFallbackBaseUrl &&
    (method === 'GET' || method === 'HEAD') &&
    (failure.isNetworkError || (failure.status !== undefined && RETRYABLE_STATUSES.has(failure.status)));
  if (__DEV__) console.warn('[api]', method, path, failure.status ?? '', failure.message);
  if (!canRetry || !env.apiFallbackBaseUrl) throw failure;

  // 운영 토큰이 다른 서버로 새지 않도록 인증 헤더는 싣지 않는다.
  const retryHeaders = { Accept: headers.Accept };
  const res = await send(buildUrl(env.apiFallbackBaseUrl, path, opts.query), { method, headers: retryHeaders }, timeout, opts.signal);
  const data = await parse(res);
  if (!res.ok) throw new ApiError(`HTTP ${res.status}`, { status: res.status, body: data });
  return data as T;
}

export const api = {
  get: <T>(path: string, opts?: Omit<RequestOptions, 'method' | 'body'>) => apiRequest<T>(path, { ...opts, method: 'GET' }),
  post: <T>(path: string, body?: unknown, opts?: Omit<RequestOptions, 'method' | 'body'>) =>
    apiRequest<T>(path, { ...opts, method: 'POST', body }),
  put: <T>(path: string, body?: unknown, opts?: Omit<RequestOptions, 'method' | 'body'>) =>
    apiRequest<T>(path, { ...opts, method: 'PUT', body }),
  delete: <T>(path: string, opts?: Omit<RequestOptions, 'method'>) => apiRequest<T>(path, { ...opts, method: 'DELETE' }),
};
