/**
 * Add "MATH-102 — Intermediate Calculus" under the Greenwood High tenant.
 *
 * Three lessons, split across two modules:
 *   Module 1: Differential Equations
 *     - Lesson 1.1: First-Order ODEs
 *     - Lesson 1.2: Separable Equations
 *   Module 2: Integral Calculus Review
 *     - Lesson 2.1: Integration by Parts
 *
 * Uses the Admin SDK so it bypasses client security rules (the
 * `tenants/...` and `courses/...` writes are denied to clients by
 * firestore.rules, by design — only server-side code may create them).
 *
 *   node firestore_seed/add_math_102.js --dry-run   # preview
 *   node firestore_seed/add_math_102.js             # apply
 *   node firestore_seed/add_math_102.js --project=elimupepe-8acc4
 *
 * Idempotent: every write is a full `set` with deterministic IDs, so
 * re-running overwrites the same documents. To remove the course, use
 * the Firebase Console or a `firebase firestore:delete` with the
 * `tenants/greenwood_high/courses/course_math_102` path.
 *
 * Conventions enforced (see firestore.rules):
 *   - tenantId on the course doc equals the path segment "greenwood_high"
 *   - courseId on the course doc equals the path segment "course_math_102"
 *   - studentCount is initialized here; the rules reject any client update
 *     that changes it, so future bumps must come from a Cloud Function.
 */

'use strict';

function parseArgs(argv) {
  const out = { projectId: null, dryRun: false };
  for (const a of argv.slice(2)) {
    if (a.startsWith('--project=')) out.projectId = a.slice('--project='.length);
    else if (a === '--dry-run') out.dryRun = true;
  }
  return out;
}

async function main() {
  const args = parseArgs(process.argv);

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
    admin.initializeApp(
      args.projectId ? { projectId: args.projectId } : undefined,
    );
  }

  const db = admin.firestore();
  const projectId = args.projectId || process.env.GCLOUD_PROJECT || '(default)';
  console.log(`Project: ${projectId}`);
  console.log(`Mode:    ${args.dryRun ? 'DRY RUN' : 'WRITE'}\n`);

  // ---------- IDs ----------
  const TENANT_ID = 'greenwood_high';
  const TEACHER_UID = 'usr_teacher_sarah';
  const COURSE_ID = 'course_math_102';
  const MODULE_1_ID = 'module_1_diff_eq';
  const MODULE_2_ID = 'module_2_integrals';
  const now = () => new Date().toISOString();

  // ---------- Course ----------
  const courseDoc = {
    courseId: COURSE_ID,
    tenantId: TENANT_ID,
    title: 'Intermediate Calculus',
    code: 'MATH-102',
    description:
      'Builds on MATH-101. Covers first-order differential equations, ' +
      'separable equations, and integral calculus techniques including ' +
      'integration by parts.',
    teacherUids: [TEACHER_UID],
    studentCount: 0,
    status: 'published',
    term: 'Spring 2027',
    createdAt: '2026-09-01T10:00:00Z',
    updatedAt: now(),
  };

  // ---------- Modules ----------
  const modules = [
    {
      _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}/modules/${MODULE_1_ID}`,
      data: {
        title: 'Module 1: Differential Equations',
        order: 1,
        isPublished: true,
        lessonCount: 2,
      },
    },
    {
      _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}/modules/${MODULE_2_ID}`,
      data: {
        title: 'Module 2: Integral Calculus Review',
        order: 2,
        isPublished: true,
        lessonCount: 1,
      },
    },
  ];

  // ---------- Lessons (three total) ----------
  const lessons = [
    {
      _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}/modules/${MODULE_1_ID}/lessons/lesson_1_1_first_order_odes`,
      data: {
        title: 'Lesson 1.1: First-Order ODEs',
        order: 1,
        contentType: 'video',
        contentUrl: `https://storage.googleapis.com/tenants/${TENANT_ID}/courses/${COURSE_ID}/lesson_1_1.mp4`,
        bodyText:
          '<h3>First-Order Ordinary Differential Equations</h3>' +
          '<p>A first-order ODE has the general form dy/dx = f(x, y). ' +
          'This lesson introduces existence and uniqueness, and walks ' +
          'through sketching direction fields.</p>',
        durationMinutes: 40,
        isFreePreview: true,
      },
    },
    {
      _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}/modules/${MODULE_1_ID}/lessons/lesson_1_2_separable_equations`,
      data: {
        title: 'Lesson 1.2: Separable Equations',
        order: 2,
        contentType: 'rich_text',
        contentUrl: '',
        bodyText:
          '<h3>Separable Equations</h3>' +
          '<p>A separable ODE can be rewritten as g(y) dy = h(x) dx. ' +
          'Integrate both sides, then apply the initial condition to ' +
          'solve for the constant of integration.</p>',
        durationMinutes: 35,
        isFreePreview: false,
      },
    },
    {
      _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}/modules/${MODULE_2_ID}/lessons/lesson_2_1_integration_by_parts`,
      data: {
        title: 'Lesson 2.1: Integration by Parts',
        order: 1,
        contentType: 'video',
        contentUrl: `https://storage.googleapis.com/tenants/${TENANT_ID}/courses/${COURSE_ID}/lesson_2_1.mp4`,
        bodyText:
          '<h3>Integration by Parts</h3>' +
          '<p>When u-substitution is not enough, integration by parts ' +
          'rewrites ∫ u dv = uv − ∫ v du. Choosing u and dv is the skill.</p>',
        durationMinutes: 45,
        isFreePreview: false,
      },
    },
  ];

  const writes = [
    { _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}`, data: courseDoc },
    ...modules,
    ...lessons,
  ];

  console.log(`Plan: ${writes.length} writes`);
  for (const w of writes) console.log(`  set  ${w._path}`);

  if (args.dryRun) {
    console.log('\n--dry-run set; nothing written.');
    return;
  }

  console.log('\nWriting...');
  const batch = db.batch();
  for (const w of writes) batch.set(db.doc(w._path), w.data, { merge: false });
  await batch.commit();

  console.log('\nDone. Verify in the Firebase Console:');
  console.log(
    `  Firestore → Data → tenants/greenwood_high/courses/${COURSE_ID}`,
  );
}

main().catch((err) => {
  console.error('\nadd_math_102 failed:', err);
  process.exit(1);
});
