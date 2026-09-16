#!/usr/bin/env node
/**
 * scripts/verify_firebase.js
 *
 * Probes the three Firebase / GCP APIs the multi-tenant LMS needs:
 *   1. Firestore API
 *   2. Firebase Auth API
 *   3. Cloud Storage for Firebase
 *
 * Exits 0 if all three respond, 1 if any fails. The first failure's
 * console link is printed so the user can enable the API in one click.
 *
 * Auth: GOOGLE_APPLICATION_CREDENTIALS must point at a service-account
 * JSON with the firebase.admin (or owner) role. If unset, defaults to
 * the project's well-known path: ./elimupepe-8acc4-firebase-adminsdk-*.json
 *
 *   node scripts/verify_firebase.js
 *   node scripts/verify_firebase.js --project=elimupepe-8acc4
 *   node scripts/verify_firebase.js --strict   # exit 1 on any failure
 */

'use strict';

const fs = require('fs');
const path = require('path');

const DEFAULT_PROJECT = 'elimupepe-8acc4';

function parseArgs(argv) {
  const out = { project: DEFAULT_PROJECT, strict: false };
  for (const a of argv.slice(2)) {
    if (a.startsWith('--project=')) out.project = a.slice('--project='.length);
    else if (a === '--strict') out.strict = true;
  }
  return out;
}

function findDefaultServiceAccount() {
  const cwd = process.cwd();
  const files = fs
    .readdirSync(cwd)
    .filter(
      (f) =>
        /^elimupepe-8acc4-firebase-adminsdk-.*\.json$/.test(f) &&
        fs.statSync(path.join(cwd, f)).isFile(),
    );
  if (files.length === 0) return null;
  // Prefer the deterministic file name if multiple exist.
  files.sort();
  return path.join(cwd, files[0]);
}

async function checkFirestore(admin) {
  try {
    const cols = await admin.firestore().listCollections();
    return { ok: true, detail: `${cols.length} top-level collection(s)` };
  } catch (e) {
    return {
      ok: false,
      code: e.code || e.name || 'ERROR',
      message: e.message,
      enableUrl: `https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=${process.env.GCLOUD_PROJECT || DEFAULT_PROJECT}`,
    };
  }
}

async function checkAuth(admin) {
  try {
    const res = await admin.auth().listUsers(1);
    return { ok: true, detail: `sampled ${res.users.length} user(s)` };
  } catch (e) {
    const code = e.code || e.name || 'ERROR';
    const msg = (e.message || '').toLowerCase();
    // Firebase Auth in this GCP project has never been provisioned.
    if (
      code === 'auth/configuration-not-found' ||
      msg.includes('no configuration') ||
      msg.includes('service is not enabled')
    ) {
      return {
        ok: false,
        code,
        message:
          'Firebase Authentication is not initialized for this project. ' +
          'Open the Console → Authentication → Get started.',
        enableUrl: `https://console.firebase.google.com/project/${process.env.GCLOUD_PROJECT || DEFAULT_PROJECT}/authentication`,
      };
    }
    return {
      ok: false,
      code,
      message: e.message,
      enableUrl: `https://console.firebase.google.com/project/${process.env.GCLOUD_PROJECT || DEFAULT_PROJECT}/authentication`,
    };
  }
}

async function checkStorage(admin) {
  try {
    const projectId = process.env.GCLOUD_PROJECT || DEFAULT_PROJECT;
    const bucketName = `${projectId}.appspot.com`;
    const bucket = admin.storage().bucket(bucketName);
    const [exists] = await bucket.exists();
    if (!exists) {
      return {
        ok: false,
        code: 'STORAGE_BUCKET_MISSING',
        message:
          `Default bucket '${bucketName}' does not exist. Initialize Storage in the Firebase Console.`,
        enableUrl: `https://console.firebase.google.com/project/${projectId}/storage`,
      };
    }
    return { ok: true, detail: bucketName };
  } catch (e) {
    const code = e.code || e.name || 'ERROR';
    const msg = (e.message || '').toLowerCase();
    if (
      msg.includes('bucket name not specified') ||
      msg.includes('invalid argument')
    ) {
      return {
        ok: false,
        code: 'STORAGE_NOT_INITIALIZED',
        message:
          'Cloud Storage is not initialized for this project. ' +
          'Open the Console → Storage → Get started.',
        enableUrl: `https://console.firebase.google.com/project/${process.env.GCLOUD_PROJECT || DEFAULT_PROJECT}/storage`,
      };
    }
    return {
      ok: false,
      code,
      message: e.message,
      enableUrl: `https://console.firebase.google.com/project/${process.env.GCLOUD_PROJECT || DEFAULT_PROJECT}/storage`,
    };
  }
}

async function main() {
  const args = parseArgs(process.argv);

  // Resolve credentials
  let credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credPath) {
    const found = findDefaultServiceAccount();
    if (found) {
      process.env.GOOGLE_APPLICATION_CREDENTIALS = found;
      credPath = found;
    }
  }
  if (!credPath) {
    console.error(
      '\nNo service account configured.\n' +
        'Set GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json\n' +
        'Or place elimupepe-8acc4-firebase-adminsdk-*.json in the project root.\n',
    );
    process.exit(1);
  }
  if (!fs.existsSync(credPath)) {
    console.error(`\nService account JSON not found: ${credPath}\n`);
    process.exit(1);
  }

  let admin;
  try {
    admin = require('firebase-admin');
  } catch (e) {
    console.error(
      '\nMissing dependency: firebase-admin.\n' +
        '  npm install --no-save firebase-admin\n',
    );
    process.exit(1);
  }

  if (admin.apps.length === 0) {
    const sa = JSON.parse(fs.readFileSync(credPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(sa),
      projectId: args.project,
    });
  }
  process.env.GCLOUD_PROJECT = args.project;

  console.log(`Project:  ${args.project}`);
  console.log(`SA JSON:  ${credPath}\n`);

  const checks = [
    ['Firestore', await checkFirestore(admin)],
    ['Auth',      await checkAuth(admin)],
    ['Storage',   await checkStorage(admin)],
  ];

  let failed = 0;
  for (const [name, res] of checks) {
    if (res.ok) {
      console.log(`  \u2714 ${name.padEnd(10)} OK  (${res.detail})`);
    } else {
      failed += 1;
      console.error(`  \u2718 ${name.padEnd(10)} FAIL  [${res.code}]`);
      console.error(`      ${res.message}`);
      console.error(`      Enable: ${res.enableUrl}`);
    }
  }

  console.log('');
  if (failed > 0) {
    console.error(
      `${failed} API check(s) failed. Enable them with the links above, ` +
        'wait ~1 minute for propagation, then re-run.',
    );
    process.exit(args.strict || failed === checks.length ? 1 : 0);
  }
  console.log('All APIs ready.');
  process.exit(0);
}

main().catch((e) => {
  console.error('verify_firebase crashed:', e);
  process.exit(1);
});
