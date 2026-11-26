#!/usr/bin/env node
/**
 * FCM HTTP v1 로 테스트 알림 1건을 보낸다(서버 없이 앱 수신·탭 이동 확인용).
 *   node scripts/send-test-push.mjs <서비스계정.json> <기기토큰 | @토큰파일> [notice | /home | /meal | /bus | /notice | /map]
 * 서비스 계정 키: Firebase 콘솔 > 프로젝트 설정 > 서비스 계정 > 새 비공개 키. 저장소에 넣지 않는다.
 * 기기 토큰: 개발 빌드 로그의 "[push] device token".
 */
import { createSign } from 'node:crypto';
import { readFileSync } from 'node:fs';

const [keyPath, tokenArg, target = 'notice'] = process.argv.slice(2);
if (!keyPath || !tokenArg) {
  console.error('사용법: node scripts/send-test-push.mjs <서비스계정.json> <기기토큰|@파일> [notice|/home|...]');
  process.exit(1);
}
const key = JSON.parse(readFileSync(keyPath, 'utf8'));
const token = tokenArg.startsWith('@') ? readFileSync(tokenArg.slice(1), 'utf8').trim() : tokenArg;

const b64 = (o) => Buffer.from(typeof o === 'string' ? o : JSON.stringify(o)).toString('base64url');
const now = Math.floor(Date.now() / 1000);
const unsigned = `${b64({ alg: 'RS256', typ: 'JWT' })}.${b64({
  iss: key.client_email,
  scope: 'https://www.googleapis.com/auth/firebase.messaging',
  aud: key.token_uri,
  iat: now,
  exp: now + 3600,
})}`;
const jwt = `${unsigned}.${createSign('RSA-SHA256').update(unsigned).sign(key.private_key, 'base64url')}`;

const auth = await fetch(key.token_uri, {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: jwt }),
});
if (!auth.ok) throw new Error(`OAuth 실패 ${auth.status}: ${await auth.text()}`);
const { access_token } = await auth.json();

// docs/PUSH.md 3장 payload. data 값은 모두 문자열이어야 한다.
const data =
  target === 'notice'
    ? { type: 'notice', id: '1', url: 'https://www.tukorea.ac.kr/', title: '테스트 공지', author: '한돌이', created_at: new Date().toISOString().slice(0, 10) }
    : { route: target };
const res = await fetch(`https://fcm.googleapis.com/v1/projects/${key.project_id}/messages:send`, {
  method: 'POST',
  headers: { Authorization: `Bearer ${access_token}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({
    message: {
      token,
      notification: { title: '한돌이 테스트 알림', body: target === 'notice' ? '눌러서 공지 상세로 이동' : `눌러서 ${target} 로 이동` },
      data,
      android: { notification: { channel_id: 'sandol_default' } },
    },
  }),
});
console.log(res.status, await res.text());
process.exit(res.ok ? 0 : 1);
