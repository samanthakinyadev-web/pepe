# Multi-Tenant LMS — Firestore & Storage Setup

This directory contains the multi-tenant Firestore architecture, security
rules, indexes, and seed scripts for the `loho-ebook-reader` Firebase
project (`elimupepe-8acc4` by default).

> **The agent cannot finish this for you.** I cannot accept Blaze billing,
> enable APIs in your GCP project, or click "Get started" in the Firebase
> Console from this chat. The script `scripts/deploy_and_seed.sh` has a
> hard gate (`scripts/verify_firebase.js`) that fails fast with the exact
> Console link for whichever API is missing — you do the click, wait a
> minute, re-run.

## Files

| File | Purpose |
| --- | --- |
| `firestore.rules` | Tenant-scoped security rules. Every nested `match` re-asserts `belongsToTenant(tenantId)` so School A cannot read or write School B. |
| `firestore.indexes.json` | The three composite indexes from the spec (active courses, pending submissions, student grades). |
| `storage.rules` | Mirrors the same tenancy on Cloud Storage: `/tenants/{tenantId}/...`, 25 MB cap, students can only write to their own submission folder. |
| `firestore_seed/seed.js` | Creates a `Greenwood High School` sample tenant: 3 users, 1 course (Math 101), 1 module, 2 lessons, 1 assignment, 1 graded submission, 1 grades entry. Uses the Admin SDK (bypasses client rules). |
| `firestore_seed/add_math_102.js` | Optional add-on: `MATH-102` course under the same tenant, 3 lessons across 2 modules. |
| `firestore_seed/set_claims.js` | Sets `tenantId` + `role` custom claims on the seeded UIDs so the security rules let them through. |
| `scripts/deploy_and_seed.sh` | One-shot runner. Auto-discovers the service-account JSON, gates on `verify_firebase.js`, then deploys rules + seeds. |
| `scripts/verify_firebase.js` | Probes Firestore, Firebase Auth, and Cloud Storage. Prints the exact Console link to enable each. |

## Provision the APIs (one-time, you, in the browser)

As of the last verification on `elimupepe-8acc4`, none of Firestore,
Firebase Auth, or Cloud Storage were initialized for this project.
Click each link, follow the prompts, wait ~1 minute.

| Step | Link |
| --- | --- |
| 1. Upgrade to **Blaze** (Firestore requires it) | https://console.firebase.google.com/project/elimupepe-8acc4/usage/details |
| 2. Enable **Firestore** | https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=elimupepe-8acc4 |
| 3. Initialize **Firebase Authentication** | https://console.firebase.google.com/project/elimupepe-8acc4/authentication |
| 4. Initialize **Cloud Storage for Firebase** | https://console.firebase.google.com/project/elimupepe-8acc4/storage |

Verify before you start:

```bash
node scripts/verify_firebase.js --strict
```

## Tree (created by `seed.js`)

```
tenants/greenwood_high                       { name, domain, ... settings }
├── users/usr_admin_001                      role: school_admin
├── users/usr_teacher_sarah                  role: teacher
├── users/usr_student_alex                   role: student
├── courses/course_math_101                  teacherUids: [usr_teacher_sarah]
│   ├── modules/module_1_diff_calc
│   │   ├── lessons/lesson_1_1_limits
│   │   └── lessons/lesson_1_2_derivatives
│   └── assignments/assign_calc_hw1
│       └── submissions/usr_student_alex     status: graded, score: 92/100
└── grades/usr_student_alex_course_math_101  percentage: 90, letter: A
```

After `add_math_102.js` also runs:

```
└── courses/course_math_102                  teacherUids: [usr_teacher_sarah]
    ├── modules/module_1_diff_eq
    │   ├── lessons/lesson_1_1_first_order_odes
    │   └── lessons/lesson_1_2_separable_equations
    └── modules/module_2_integrals
        └── lessons/lesson_2_1_integration_by_parts
```

## Run it (you, in your shell)

### One-shot

```bash
bash scripts/deploy_and_seed.sh
```

This chains: `firebase use` → `npm install firebase-admin` →
`firebase deploy --only firestore:rules,firestore:indexes,storage` →
`seed.js` → `add_math_102.js` → `set_claims.js`. Use `--dry-run` to
preview without touching the project.

### Step-by-step

```bash
# 1. One-time: log in to Firebase
firebase login

# 2. Pin the project
firebase use elimupepe-8acc4

# 3. Install Admin SDK locally (no global install needed)
npm install --no-save firebase-admin

# 4. Dry-run first
node firestore_seed/seed.js --dry-run
node firestore_seed/add_math_102.js --dry-run

# 5. Apply
node firestore_seed/seed.js
node firestore_seed/add_math_102.js

# 6. Create the corresponding Firebase Auth users
#    (Firebase Console → Authentication → Add user) with these UIDs:
#      usr_admin_001
#      usr_teacher_sarah
#      usr_student_alex

# 7. Set custom claims so security rules let them in
node firestore_seed/set_claims.js

# 8. Deploy rules + indexes + storage rules
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Multi-tenancy rules — what to keep in mind

- **Custom claims are the source of truth.** `request.auth.token.tenantId`
  and `request.auth.token.role` are read by every helper function. They are
  set on the server (Cloud Function / Admin SDK), never by the client.
- **Tenant scope is checked on every nested `match`.** Subcollections are
  not auto-secured by the parent rule; `match /tenants/{tenantId}/courses/...`
  re-asserts `belongsToTenant(tenantId)`.
- **Denormalized fields are server-maintained.** `studentCount` on a course
  and any `/grades/{gradeId}` document are written by trusted code paths
  only; client writes are denied.
- **Submissions are keyed by student UID.** `submissionId == studentUid`,
  enforced in the `create` rule, so a student has exactly one primary
  submission per assignment.
- **Storage tenancy mirrors Firestore.** `/tenants/{tenantId}/...` — students
  can only upload under their own UID subfolder.

## App-side integration

The Flutter app in this repo currently does **not** use Firestore for LMS
data — it talks to a PHP backend at `elimupepe.loholearning.co.ke`. The
Firestore tree in this directory is the target architecture for a future
migration (or for a Firebase-native admin/parent panel that talks to the
same project). No app code was changed.
