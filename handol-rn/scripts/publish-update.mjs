#!/usr/bin/env node
/**
 * OTA 업데이트 배포물 만들기 (docs/OTA_UPDATE_SERVER.md).
 *   node scripts/publish-update.mjs [android|ios|all] [--runtime=0.3.21,0.3.22]   (기본 android, 지금 앱 버전)
 * --runtime: 이 번들을 다른 설치 파일 버전에도 낸다. 그 설치 파일에 번들이 쓰는 네이티브 모듈이 다 있을 때만 쓴다.
 * JS 번들을 export 하고, 매니페스트를 keys/private-key.pem 으로 서명해 updates-out/ 에 쓴다.
 * updates-out/ 을 서버 데이터 폴더에 그대로 덮어 올리면(rsync 등) 배포된다. 서버는 개인키를 모른다.
 */
import { execSync } from 'node:child_process';
import { createHash, createSign, createVerify, randomUUID, X509Certificate } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const BASE_URL = 'https://update.handol.app';
const ROOT = path.resolve(import.meta.dirname, '..');
const DIST = path.join(ROOT, 'dist');
const OUT = path.join(ROOT, 'updates-out');
const KEY = process.env.OTA_PRIVATE_KEY ?? path.join(ROOT, 'keys', 'private-key.pem');
const CERT = path.join(ROOT, 'certs', 'certificate.pem');
const TYPES = { png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg', gif: 'image/gif', webp: 'image/webp', xml: 'application/xml', ttf: 'font/ttf', otf: 'font/otf', json: 'application/json', mp4: 'video/mp4' };

const runtimeArg = process.argv.find((a) => a.startsWith('--runtime='));
const arg = process.argv.slice(2).find((a) => !a.startsWith('--')) ?? 'android';
const platforms = arg === 'all' ? ['android', 'ios'] : [arg];
if (!platforms.every((p) => p === 'android' || p === 'ios')) throw new Error('플랫폼은 android | ios | all');
if (!fs.existsSync(KEY)) throw new Error('서명 개인키가 없습니다: ' + KEY);

const run = (cmd) => execSync(cmd, { cwd: ROOT, stdio: ['ignore', 'pipe', 'inherit'], encoding: 'utf8' });
const config = JSON.parse(run('npx expo config --json --type public'));
const rv = typeof config.runtimeVersion === 'string' ? config.runtimeVersion
  : config.runtimeVersion?.policy === 'appVersion' ? config.version : null;
if (!rv) throw new Error('runtimeVersion 정책이 appVersion 또는 문자열이어야 합니다');
const runtimes = runtimeArg ? runtimeArg.slice('--runtime='.length).split(',').map((v) => v.trim()) : [rv];
if (!runtimes.every((v) => /^[A-Za-z0-9._-]+$/.test(v))) throw new Error('--runtime 값이 잘못됐습니다');

fs.rmSync(DIST, { recursive: true, force: true });
run('npx expo export --output-dir dist ' + platforms.map((p) => '--platform ' + p).join(' '));
const metadata = JSON.parse(fs.readFileSync(path.join(DIST, 'metadata.json'), 'utf8'));
const key = fs.readFileSync(KEY, 'utf8');
const publicKey = new X509Certificate(fs.readFileSync(CERT)).publicKey;

/** 파일을 내용 주소(sha256)로 files/ 에 복사하고 매니페스트 항목을 돌려준다 */
function asset(rel, ext, contentType) {
  const bytes = fs.readFileSync(path.join(DIST, rel));
  const hash = createHash('sha256').update(bytes).digest('base64url');
  const name = hash + '.' + ext;
  fs.mkdirSync(path.join(OUT, 'files'), { recursive: true });
  fs.writeFileSync(path.join(OUT, 'files', name), bytes);
  return { hash, key: createHash('md5').update(bytes).digest('hex'), contentType, fileExtension: '.' + ext, url: BASE_URL + '/files/' + name };
}

for (const platform of platforms) for (const rv of runtimes) {
  const meta = metadata.fileMetadata[platform];
  const createdAt = new Date();
  const manifest = JSON.stringify({
    id: randomUUID(),
    createdAt: createdAt.toISOString(),
    runtimeVersion: rv,
    launchAsset: asset(meta.bundle.replaceAll('\\', '/'), 'hbc', 'application/javascript'),
    assets: meta.assets.map((a) => asset(a.path.replaceAll('\\', '/'), a.ext, TYPES[a.ext] ?? 'application/octet-stream')),
    metadata: {},
    // 앱의 Constants.expoConfig(=src/core/env.ts 의 extra)가 이 값을 읽는다
    extra: { expoClient: config },
  });
  const sig = createSign('RSA-SHA256').update(manifest).sign(key, 'base64');
  if (!createVerify('RSA-SHA256').update(manifest).verify(publicKey, sig, 'base64')) {
    throw new Error('개인키가 앱의 certs/certificate.pem 과 짝이 아닙니다');
  }
  const dir = path.join(OUT, 'manifests', rv, platform);
  fs.mkdirSync(dir, { recursive: true });
  const id = JSON.parse(manifest).id;
  const file = path.join(dir, String(createdAt.getTime()) + '-' + id + '.json');
  fs.writeFileSync(file, JSON.stringify({ manifest, signature: 'sig="' + sig + '", keyid="main"' }));
  console.log(platform + ' runtime ' + rv + ' 업데이트 ' + id + ' → ' + path.relative(ROOT, file));
}
