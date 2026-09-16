/**
 * Firestore seed for the multi-tenant LMS.
 *
 * Creates a "Greenwood High School" sample tenant with:
 *   - tenant metadata
 *   - 1 school admin, 1 teacher, 1 student
 *   - 1 course (Math 101) with 1 module + 2 lessons
 *   - 1 assignment
 *   - 1 student submission (graded)
 *   - 1 grades ledger entry
 *
 * Run with the Firebase Admin SDK (bypasses client security rules):
 *
 *   # 1. Authenticate (one of):
 *   firebase login
 *   # or set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON
 *
 *   # 2. Set the project
 *   firebase use <your-project-id>
 *
 *   # 3. Install firebase-admin locally (one time)
 *   npm install --no-save firebase-admin
 *
 *   # 4. Run
 *   node firestore_seed/seed.js
 *
 *   # Optional flags:
 *   node firestore_seed/seed.js --project=elimupepe-8acc4
 *   node firestore_seed/seed.js --dry-run   # prints writes without applying
 */

'use strict';

const path = require('path');

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
      'Install it locally with:\n' +
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
  const FieldValue = admin.firestore.FieldValue;
  const projectId = args.projectId || process.env.GCLOUD_PROJECT || '(default)';
  console.log(`Project: ${projectId}`);
  console.log(`Mode:    ${args.dryRun ? 'DRY RUN' : 'WRITE'}`);

  // ---------- IDs ----------
  const TENANT_ID = 'greenwood_high';
  const ADMIN_UID = 'usr_admin_001';
  const TEACHER_UID = 'usr_teacher_sarah';
  const STUDENT_UID = 'usr_student_alex';
  const COURSE_ID = 'course_math_101';
  const MODULE_ID = 'module_1_diff_calc';
  const LESSON_1_ID = 'lesson_1_1_limits';
  const LESSON_2_ID = 'lesson_1_2_derivatives';
  const ASSIGNMENT_ID = 'assign_calc_hw1';
  const SUBMISSION_ID = STUDENT_UID; // one submission per student per assignment
  const GRADE_ID = `${STUDENT_UID}_${COURSE_ID}`;

  const now = () => new Date().toISOString();

  // ---------- Tenant metadata ----------
  const tenantDoc = {
    name: 'Greenwood High School',
    domain: 'greenwood.lms.com',
    customDomain: 'lms.greenwood.edu',
    subscriptionTier: 'enterprise',
    isActive: true,
    createdAt: '2026-02-15T08:00:00Z',
    updatedAt: now(),
    settings: {
      allowStudentDiscussion: true,
      maxFileSizeMb: 25,
      primaryColor: '#1E3A8A',
    },
  };

  // ---------- Users ----------
  const users = [
    {
      _path: `tenants/${TENANT_ID}/users/${ADMIN_UID}`,
      data: {
        uid: ADMIN_UID,
        email: 'admin@greenwood.edu',
        displayName: 'Pat Morgan',
        role: 'school_admin',
        photoURL: '',
        tenantId: TENANT_ID,
        enrolledCourseIds: [],
        createdAt: '2026-02-20T09:00:00Z',
      },
    },
    {
      _path: `tenants/${TENANT_ID}/users/${TEACHER_UID}`,
      data: {
        uid: TEACHER_UID,
        email: 'sarah.jenkins@greenwood.edu',
        displayName: 'Sarah Jenkins',
        role: 'teacher',
        photoURL: '',
        tenantId: TENANT_ID,
        enrolledCourseIds: [COURSE_ID],
        createdAt: '2026-03-01T09:15:00Z',
      },
    },
    {
      _path: `tenants/${TENANT_ID}/users/${STUDENT_UID}`,
      data: {
        uid: STUDENT_UID,
        email: 'alex.rivera@greenwood.edu',
        displayName: 'Alex Rivera',
        role: 'student',
        photoURL: '',
        tenantId: TENANT_ID,
        enrolledCourseIds: [COURSE_ID],
        createdAt: '2026-08-15T08:00:00Z',
      },
    },
  ];

  // ---------- Course ----------
  const courseDoc = {
    courseId: COURSE_ID,
    tenantId: TENANT_ID,
    title: 'Introduction to Calculus',
    code: 'MATH-101',
    description:
      'Fundamental concepts of limits, derivatives, and integrals.',
    teacherUids: [TEACHER_UID],
    studentCount: 1,
    status: 'published',
    term: 'Fall 2026',
    createdAt: '2026-08-01T10:00:00Z',
    updatedAt: now(),
  };

  // ---------- Module ----------
  const moduleDoc = {
    title: 'Module 1: Differential Calculus',
    order: 1,
    isPublished: true,
    lessonCount: 2,
  };

  // ---------- Lessons ----------
  const lessons = [
    {
      _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}/modules/${MODULE_ID}/lessons/${LESSON_1_ID}`,
      data: {
        title: 'Lesson 1.1: Limits and Continuity',
        order: 1,
        contentType: 'video',
        contentUrl: `https://storage.googleapis.com/tenants/${TENANT_ID}/courses/${COURSE_ID}/video_lesson_1_1.mp4`,
        bodyText:
          '<h3>Understanding Limits</h3><p>A limit is the value that a function approaches...</p>',
        durationMinutes: 45,
        isFreePreview: false,
      },
    },
    {
      _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}/modules/${MODULE_ID}/lessons/${LESSON_2_ID}`,
      data: {
        title: 'Lesson 1.2: Derivatives',
        order: 2,
        contentType: 'rich_text',
        contentUrl: '',
        bodyText:
          '<h3>Derivatives</h3><p>The derivative measures the instantaneous rate of change...</p>',
        durationMinutes: 50,
        isFreePreview: true,
      },
    },
  ];

  // ---------- Assignment ----------
  const assignmentDoc = {
    assignmentId: ASSIGNMENT_ID,
    courseId: COURSE_ID,
    tenantId: TENANT_ID,
    title: 'Limits Problem Set #1',
    instructions:
      'Complete problems 1 through 15 on page 42. Upload a single PDF file.',
    maxPoints: 100,
    dueAt: '2026-09-15T23:59:59Z',
    allowLateSubmissions: true,
    allowedFileExtensions: ['pdf'],
    createdByUid: TEACHER_UID,
    createdAt: '2026-09-01T08:00:00Z',
  };

  // ---------- Submission (graded) ----------
  const submissionDoc = {
    submissionId: SUBMISSION_ID,
    studentUid: STUDENT_UID,
    studentName: 'Alex Rivera',
    assignmentId: ASSIGNMENT_ID,
    courseId: COURSE_ID,
    tenantId: TENANT_ID,
    status: 'graded',
    submittedAt: '2026-09-14T19:30:00Z',
    fileAttachments: [
      {
        fileName: 'alex_rivera_hw1.pdf',
        fileUrl: `https://storage.googleapis.com/tenants/${TENANT_ID}/courses/${COURSE_ID}/submissions/${STUDENT_UID}/hw1.pdf`,
        fileSizeBytes: 2048500,
      },
    ],
    grade: {
      score: 92,
      maxPoints: 100,
      gradedByUid: TEACHER_UID,
      gradedAt: '2026-09-16T11:00:00Z',
      feedback:
        'Great work on derivatives! Watch out for rounding errors in problem 4.',
    },
  };

  // ---------- Grades ledger ----------
  const gradeDoc = {
    gradeId: GRADE_ID,
    studentUid: STUDENT_UID,
    courseId: COURSE_ID,
    tenantId: TENANT_ID,
    totalScore: 450,
    totalPossiblePoints: 500,
    percentage: 90.0,
    letterGrade: 'A',
    updatedAt: '2026-09-16T11:00:00Z',
  };

  // ---------- Plan ----------
  const writes = [
    { _path: `tenants/${TENANT_ID}`, data: tenantDoc },
    ...users,
    {
      _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}`,
      data: courseDoc,
    },
    {
      _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}/modules/${MODULE_ID}`,
      data: moduleDoc,
    },
    ...lessons,
    {
      _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}/assignments/${ASSIGNMENT_ID}`,
      data: assignmentDoc,
    },
    {
      _path: `tenants/${TENANT_ID}/courses/${COURSE_ID}/assignments/${ASSIGNMENT_ID}/submissions/${SUBMISSION_ID}`,
      data: submissionDoc,
    },
    {
      _path: `tenants/${TENANT_ID}/grades/${GRADE_ID}`,
      data: gradeDoc,
    },
  ];

  console.log(`\nPlan: ${writes.length} writes\n`);
  for (const w of writes) {
    console.log(`  set  ${w._path}`);
  }

  if (args.dryRun) {
    console.log('\n--dry-run set; nothing written.');
    return;
  }

  console.log('\nWriting...');
  const batch = db.batch();
  for (const w of writes) {
    batch.set(db.doc(w._path), w.data, { merge: false });
  }
  await batch.commit();

  console.log('\nDone. Next steps:');
  console.log(
    '  1. firebase deploy --only firestore:rules,firestore:indexes,storage',
  );
  console.log(
    '  2. Set custom claims for the UIDs so they pass the security rules:',
  );
  console.log('     node firestore_seed/set_claims.js');
}

main().catch((err) => {
  console.error('\nSeed failed:', err);
  process.exit(1);
});
