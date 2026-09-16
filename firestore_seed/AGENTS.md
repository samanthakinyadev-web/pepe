# Firestore seed directory

Files in this directory are written and run by a human (or a trusted automation) with the Firebase Admin SDK. They are not part of the Flutter app build.

## Before running

1. `firebase login` (browser flow) **or** set `GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json`.
2. `firebase use elimupepe-8acc4`.
3. `npm install --no-save firebase-admin` (one-off, no global install needed).

## Order of operations

```
node firestore_seed/seed.js --dry-run   # preview writes
node firestore_seed/seed.js             # apply
# create the 3 Auth users in Firebase Console
node firestore_seed/set_claims.js       # set tenantId + role claims
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Conventions enforced by firestore.rules

- `submissionId == studentUid`
- `role ∈ {student, teacher, school_admin}`
- `studentCount` is server-maintained (rules reject client updates that change it)
- `/grades/*` is read-only for clients
- `tenantId` on every document must match the path segment

See `README.md` for the full runbook and `../.kilo/skill/firebase-lms-arch/SKILL.md` for the architecture context.
