/**
 * Set Firebase Auth custom claims for the seeded sample users.
 *
 * Without these claims, the firestore.rules helpers (belongsToTenant,
 * isTeacher, isStudent, isTenantAdmin) all return false and the user is
 * locked out of everything.
 *
 *   node firestore_seed/set_claims.js
 *
 * Idempotent: safe to re-run.
 */

'use strict';

async function main() {
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

  if (admin.apps.length === 0) admin.initializeApp();

  const TENANT_ID = 'greenwood_high';
  const claims = [
    { uid: 'usr_admin_001', claims: { tenantId: TENANT_ID, role: 'school_admin' } },
    { uid: 'usr_teacher_sarah', claims: { tenantId: TENANT_ID, role: 'teacher' } },
    { uid: 'usr_student_alex', claims: { tenantId: TENANT_ID, role: 'student' } },
  ];

  for (const { uid, claims: c } of claims) {
    try {
      await admin.auth().setCustomUserClaims(uid, c);
      console.log(`  set  ${uid} -> ${JSON.stringify(c)}`);
    } catch (err) {
      if (err.code === 'auth/user-not-found') {
        console.warn(
          `  skip ${uid} (no Firebase Auth user yet). ` +
            `Create the user in the Firebase Console (or via Admin SDK) first, ` +
            `then re-run this script.`,
        );
      } else {
        throw err;
      }
    }
  }

  console.log('\nDone. Existing custom claims take effect on the next ID token refresh.');
}

main().catch((err) => {
  console.error('\nset_claims failed:', err);
  process.exit(1);
});
