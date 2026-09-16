---
name: firebase-lms-arch
description: Multi-tenant Firestore architecture, rules philosophy, and seed conventions for the loho-ebook-reader / elimupepe Firebase project. Load whenever the Firebase MCP is asked to write data, deploy rules, or generate sample documents.
---

# Firebase LMS — project context for the Firebase MCP

## Project

- **Project ID:** `elimupepe-8acc4`
- **Default alias:** use `firebase use elimupepe-8acc4` before any deploy or Admin SDK call.
- **Source of truth files in this repo:**
  - `firestore.rules` — security rules (already written, must be deployed)
  - `firestore.indexes.json` — composite indexes
  - `storage.rules` — Cloud Storage rules
  - `firestore_seed/seed.js` — Admin SDK seed (uses `firebase-admin`, bypasses client rules)
  - `firestore_seed/set_claims.js` — sets `tenantId` + `role` custom claims
  - `firestore_seed/README.md` — full runbook

## Tenancy model

- Single Firebase project, **logical multi-tenancy**.
- Every document the user can reach lives under `/tenants/{tenantId}/...`.
- `tenantId` and `role` are stored as **Firebase Auth custom claims**, never as the only copy on the doc.
- Helper functions in `firestore.rules` (do not redefine):
  - `belongsToTenant(tenantId)`
  - `isTeacher(tenantId)` (teacher OR school_admin)
  - `isStudent(tenantId)`
  - `isTenantAdmin(tenantId)`

## Tree (the canonical shape)

```
tenants/{tenantId}
├── { metadata: name, domain, customDomain, subscriptionTier, isActive, settings }
├── users/{userId}                  uid, email, displayName, role, enrolledCourseIds[]
├── courses/{courseId}              teacherUids[], studentCount, status, term
│   ├── modules/{moduleId}          title, order, isPublished, lessonCount
│   │   └── lessons/{lessonId}      title, order, contentType, contentUrl, bodyText, durationMinutes, isFreePreview
│   └── assignments/{assignmentId}  title, instructions, maxPoints, dueAt, allowLateSubmissions, allowedFileExtensions, createdByUid
│       └── submissions/{submissionId}    submissionId MUST equal studentUid
├── grades/{gradeId}                server-only ledger; clients can read, never write
```

## Hard rules the MCP must respect

1. **Tenant scoping:** never write a document at the root of a `tenants/{tenantId}/...` path that does not carry `tenantId` matching the path segment.
2. **Submissions are keyed by student UID:** `submissionId == studentUid`. If a payload uses any other id, refuse.
3. **No client writes to `/grades/...`** — the rules deny it. Only the Admin SDK / a Cloud Function may write; if the user wants client-side grading, redesign first, do not patch.
4. **`studentCount` on courses is server-maintained.** The rules reject client updates that change it. The MCP can write the initial value during seeding, but any later change must come from a Cloud Function.
5. **Roles allowed:** `student`, `teacher`, `school_admin`. Anything else is rejected in the `create` rule for `/users/{userId}`.
6. **Custom claims are server-only.** Never set `tenantId` or `role` via the client SDK; the Admin SDK (`admin.auth().setCustomUserClaims`) is the only path.

## Sample IDs the seed uses (re-use these for "add a few more" requests)

| Kind | ID |
| --- | --- |
| Tenant | `greenwood_high` |
| School admin | `usr_admin_001` |
| Teacher | `usr_teacher_sarah` |
| Student | `usr_student_alex` |
| Course | `course_math_101` |
| Module | `module_1_diff_calc` |
| Lessons | `lesson_1_1_limits`, `lesson_1_2_derivatives` |
| Assignment | `assign_calc_hw1` |
| Submission | `usr_student_alex` (same as student UID) |
| Grade | `usr_student_alex_course_math_101` |

## How the MCP should answer common requests

- **"Add another course"** → write under `tenants/greenwood_high/courses/{newId}` with `tenantId: "greenwood_high"`, `status: "published"` (or `"draft"`), `studentCount: 0`, `teacherUids: [usr_teacher_sarah]`. Use the Admin SDK (Firestore MCP tool that maps to Admin, not the client SDK).
- **"Add another student"** → write a doc at `tenants/greenwood_high/users/{uid}` with `role: "student"`. After writing the Firestore doc, call `setCustomUserClaims(uid, { tenantId: "greenwood_high", role: "student" })` so the user passes `belongsToTenant`.
- **"Add a new tenant"** → write `tenants/{newTenantId}` with metadata. Tell the user that custom claims for users in the new tenant must be set before the users can sign in successfully.
- **"Deploy the rules"** → run `firebase deploy --only firestore:rules,firestore:indexes,storage` (the `firebase.json` in this repo already points at the local files). Do not run a full `firebase deploy`; that would try to deploy the Flutter app config and may push unintended changes.
- **"Read the rules"** → read `firestore.rules` from the repo; do not re-derive them from the description in this skill.

## When NOT to use the Firebase MCP

- For app business data, this Flutter app currently talks to a PHP backend at `elimupepe.loholearning.co.ke`. The Firebase MCP is for the Firestore/Storage architecture in this repo, not for the PHP API.
- For Analytics / Crashlytics / Performance, the Firebase MCP exposes tools for those, but they are observational only — do not delete Crashlytics data without explicit confirmation.

## Authentication

- The MCP server needs a logged-in Firebase user. In a fresh session, the first MCP call will return "you are not logged in". The user (human) must run `firebase login` in their terminal before MCP tools can write. CI/server use requires `FIREBASE_TOKEN` (deprecated) or `GOOGLE_APPLICATION_CREDENTIALS` pointing at a service-account JSON.
