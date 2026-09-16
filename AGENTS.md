# AGENTS.md — loho-ebook-reader (Elimu Pepe)

This repo is a Flutter Android app for secure learner access to ebooks.
The **runtime backend** is a PHP API at `elimupepe.loholearning.co.ke`
(see `lib/core/config/app_endpoints.dart`). The **Firebase project**
`elimupepe-8acc4` is currently used for Auth, Crashlytics, Performance,
Analytics, and Storage of bundled ebook assets.

A **multi-tenant Firestore LMS architecture** has been laid down in this
repo as future-facing infrastructure. It is *not* yet wired into the
running app — the app still talks to the PHP backend. Treat the Firestore
tree as a parallel architecture that a future migration (or a parallel
admin/parent panel) can adopt.

## What lives in this repo for the multi-tenant LMS

| File | Role |
| --- | --- |
| `firestore.rules` | Tenant-scoped security rules. Every nested `match` re-asserts `belongsToTenant(tenantId)`. `studentCount` on courses and all of `/grades/*` are server-only. |
| `firestore.indexes.json` | Composite indexes for active courses, pending submissions, student grades. |
| `storage.rules` | `/tenants/{tenantId}/...` paths; 25 MB cap; students can only write under their own UID in `submissions/`. |
| `firebase.json` | Flutter block (unchanged) + `firestore` and `storage` deploy targets. |
| `firestore_seed/seed.js` | Admin-SDK seed: Greenwood High tenant, 3 users, Math 101 course, 1 module, 2 lessons, 1 assignment, 1 graded submission, 1 grade ledger entry. Idempotent. Has `--dry-run`. |
| `firestore_seed/add_math_102.js` | Admin-SDK add-on: Math 102 course with 3 lessons across 2 modules. |
| `firestore_seed/set_claims.js` | Sets `tenantId` + `role` custom claims on the seeded UIDs. |
| `firestore_seed/AGENTS.md` | Runbook for the seed dir. |
| `firestore_seed/README.md` | Long-form runbook. |
| `scripts/deploy_and_seed.sh` | One-shot bash runbook: `firebase use`, install admin SDK, deploy rules/indexes/storage, run the seed, run the claims script. |
| `kilo.json` | Kilo config (project): registers the `firebase` MCP server (`firebase-tools mcp --dir .`). |
| `.kilo/kilo.json` | Same MCP config in the canonical config dir. |
| `.kilo/skill/firebase-lms-arch/SKILL.md` | Skill loaded by Kilo / the Firebase MCP for project-specific context (project ID, sample IDs, hard rules, common-request translations). |

## Hard rules the agent must respect (also in the skill)

1. **Tenant scoping:** every doc the user can reach lives at
   `/tenants/{tenantId}/...` and carries `tenantId` equal to the path segment.
2. **Submissions are keyed by student UID:** `submissionId == studentUid`.
3. **No client writes to `/grades/...`** — only the Admin SDK / Cloud Functions.
4. **`studentCount` is server-maintained.** Rules reject client updates that
   change it. Initial value is set during seeding.
5. **Roles:** `student`, `teacher`, `school_admin` only.
6. **Custom claims are server-only.** Use `admin.auth().setCustomUserClaims`.
7. **The PHP API is the runtime source of truth** for the app today. Do not
   remove or replace PHP-backed code in `lib/` without an explicit migration
   plan.

## Deploy / seed (one command, in your terminal)

```bash
bash scripts/deploy_and_seed.sh
```

The script:
1. Asserts you are in the project root and the Firebase CLI is installed.
2. Resolves a service-account JSON (env var, or any `elimupepe-8acc4-firebase-adminsdk-*.json` in the project root).
3. Runs `firebase use elimupepe-8acc4`.
4. Installs `firebase-admin` locally (no global install).
5. **Runs `scripts/verify_firebase.js`** — a hard gate that probes Firestore, Firebase Auth, and Cloud Storage. If any API is not enabled, the script stops with a clickable link to the right Console page.
6. Deploys `firestore:rules`, `firestore:indexes`, `storage`.
7. Runs `seed.js` (Greenwood tenant + Math 101).
8. Runs `add_math_102.js` (Math 102 with three lessons).
9. Runs `set_claims.js` (writes the custom claims).

## Project provisioning — must be done by a human in the Console

`elimupepe-8acc4` is currently only set up for Auth, Crashlytics, Performance,
Analytics, and (Storage for the bundled ebook assets). For the multi-tenant
LMS the project also needs (in this order):

1. **Firestore** — enable the API:
   https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=elimupepe-8acc4
   (Requires the project to be on the **Blaze** plan. Upgrade at
   https://console.firebase.google.com/project/elimupepe-8acc4/usage/details.)
2. **Firebase Authentication** — initialize in the Console:
   https://console.firebase.google.com/project/elimupepe-8acc4/authentication
3. **Cloud Storage for Firebase** — initialize in the Console (creates the
   default `elimupepe-8acc4.appspot.com` bucket):
   https://console.firebase.google.com/project/elimupepe-8acc4/storage

Until all three are done, `bash scripts/deploy_and_seed.sh` will stop at step
5 with the exact link to the one that's missing.

## Service account

`elimupepe-8acc4-firebase-adminsdk-fbsvc-*.json` is a Google-issued service
account key. It bypasses client security rules, which is what the seed
scripts need (Firestore denies direct client writes to `tenants/*`,
`courses/*`, `/grades/*`, etc., by design). Keep the JSON file out of git:

```bash
echo 'elimupepe-8acc4-firebase-adminsdk-*.json' >> .gitignore
```

If the file is dropped into the project root, `deploy_and_seed.sh` will
auto-discover it. Otherwise, set `GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json`.

## Using the Firebase MCP

Once the MCP is loaded in a Kilo session and you are logged in
(`firebase login`), the agent can:
- read/write Firestore docs through the Admin SDK MCP tools,
- deploy rules and indexes,
- read Storage objects.

The agent **must** read `.kilo/skill/firebase-lms-arch/SKILL.md` first to
get project ID, sample IDs, and the hard rules above. It is the single
source of truth for the architecture.

## App code

Do not modify `lib/` to add Firestore-backed screens. The Flutter app
talks to the PHP backend. If a future task requires Firestore in the app,
plan the migration explicitly with the user first.
