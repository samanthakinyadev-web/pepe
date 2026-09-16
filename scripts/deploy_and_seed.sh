#!/usr/bin/env bash
# scripts/deploy_and_seed.sh
#
# One-shot multi-tenant LMS deploy + seed for the loho-ebook-reader project.
# Run from the project root after `firebase login` (one time, browser).
#
# Order of operations:
#   1. Sanity checks (cwd, firebase CLI, node)
#   2. Resolve service-account credentials
#   3. firebase use <project>
#   4. npm install --no-save firebase-admin
#   5. scripts/verify_firebase.js   <-- hard gate, exits if APIs not ready
#   6. firebase deploy --only firestore:rules,firestore:indexes,storage
#   7. node firestore_seed/seed.js
#   8. node firestore_seed/add_math_102.js
#   9. node firestore_seed/set_claims.js
#
# Flags:
#   --project=elimupepe-8acc4    Override project (default: env $FIREBASE_PROJECT or elimupepe-8acc4)
#   --dry-run                    Print the plan without touching the project
#   --skip-deploy                Skip rules/indexes/storage deploy
#   --skip-seed                  Skip the Admin-SDK seed scripts
#   --skip-verify                Skip the API readiness probe (not recommended)
#   -h | --help                  Show usage

set -euo pipefail

# ---------- Args ----------
PROJECT="${FIREBASE_PROJECT:-elimupepe-8acc4}"
DRY_RUN=0
SKIP_DEPLOY=0
SKIP_SEED=0
SKIP_VERIFY=0

for a in "$@"; do
  case "$a" in
    --project=*)    PROJECT="${a#--project=}" ;;
    --dry-run)      DRY_RUN=1 ;;
    --skip-deploy)  SKIP_DEPLOY=1 ;;
    --skip-seed)    SKIP_SEED=1 ;;
    --skip-verify)  SKIP_VERIFY=1 ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    *) echo "Unknown flag: $a" >&2; exit 2 ;;
  esac
done

# ---------- Pretty ----------
say()  { printf '\033[1;36m\u25B6 %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m\u2714 %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m\u2718 %s\033[0m\n' "$*" >&2; exit 1; }

# ---------- Sanity ----------
say "Sanity checks"
[[ -f firebase.json ]]                  || die "Run from the project root (firebase.json not found)."
[[ -f firestore.rules ]]                || die "firestore.rules not found."
[[ -f firestore.indexes.json ]]         || die "firestore.indexes.json not found."
[[ -f storage.rules ]]                  || die "storage.rules not found."
[[ -f firestore_seed/seed.js ]]         || die "firestore_seed/seed.js not found."
[[ -f firestore_seed/add_math_102.js ]] || die "firestore_seed/add_math_102.js not found."
[[ -f firestore_seed/set_claims.js ]]   || die "firestore_seed/set_claims.js not found."
[[ -f scripts/verify_firebase.js ]]     || die "scripts/verify_firebase.js not found."
command -v firebase >/dev/null          || die "firebase CLI not on PATH. Install: npm i -g firebase-tools"
command -v node     >/dev/null          || die "node not on PATH."
command -v npm      >/dev/null          || die "npm not on PATH."

if (( DRY_RUN )); then
  say "DRY RUN — printing plan only"
  cat <<EOF
  1. firebase use ${PROJECT}
  2. resolve GOOGLE_APPLICATION_CREDENTIALS (or pick project SA JSON)
  3. npm install --no-save firebase-admin
  4. node scripts/verify_firebase.js --project=${PROJECT}
  5. firebase deploy --only firestore:rules,firestore:indexes,storage
  6. node firestore_seed/seed.js --project=${PROJECT}
  7. node firestore_seed/add_math_102.js --project=${PROJECT}
  8. node firestore_seed/set_claims.js
EOF
  exit 0
fi

ok "All sanity checks passed."

# ---------- Service-account credentials ----------
say "Resolving service account"
if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  # Auto-discover: any elimupepe-8acc4-firebase-adminsdk-*.json in cwd.
  found=$(ls elimupepe-8acc4-firebase-adminsdk-*.json 2>/dev/null | head -1 || true)
  if [[ -n "$found" ]]; then
    export GOOGLE_APPLICATION_CREDENTIALS="$PWD/$found"
    ok "Using $GOOGLE_APPLICATION_CREDENTIALS"
  else
    die "GOOGLE_APPLICATION_CREDENTIALS is unset and no project SA JSON found in cwd. Either set the env var or drop elimupepe-8acc4-firebase-adminsdk-*.json into the project root."
  fi
else
  [[ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]] \
    || die "GOOGLE_APPLICATION_CREDENTIALS points at a non-existent file: $GOOGLE_APPLICATION_CREDENTIALS"
  ok "Using $GOOGLE_APPLICATION_CREDENTIALS"
fi

# ---------- 1. Project ----------
say "firebase use ${PROJECT}"
firebase use "$PROJECT"

# ---------- 2. firebase-admin ----------
say "Installing firebase-admin (local, no global)"
npm install --no-save firebase-admin

# ---------- 3. Readiness probe (hard gate) ----------
if (( SKIP_VERIFY )); then
  warn "--skip-verify set; skipping the API readiness probe. Deploy may fail."
else
  say "Verifying Firebase APIs are enabled on ${PROJECT}"
  if node scripts/verify_firebase.js --project="$PROJECT" --strict; then
    ok "Firestore, Auth, and Storage are ready."
  else
    die "API readiness check failed. Enable the failing API(s) via the link(s) printed above, wait ~1 minute, then re-run."
  fi
fi

# ---------- 4. Deploy rules / indexes / storage ----------
if (( SKIP_DEPLOY )); then
  warn "--skip-deploy set; skipping rules/indexes/storage deploy"
else
  say "Deploying rules, indexes, and storage rules"
  firebase deploy --only firestore:rules,firestore:indexes,storage
  ok "Rules, indexes, and storage deployed."
fi

# ---------- 5–7. Seeds ----------
if (( SKIP_SEED )); then
  warn "--skip-seed set; skipping Admin SDK seed scripts"
else
  say "Seeding Greenwood + Math 101"
  node firestore_seed/seed.js --project="$PROJECT"

  say "Adding Math 102 (3 lessons across 2 modules)"
  node firestore_seed/add_math_102.js --project="$PROJECT"

  say "Setting custom claims (tenantId + role)"
  node firestore_seed/set_claims.js

  ok "Seeds complete."
fi

cat <<'EOF'

✔ Done.

Next steps:
  1. Firebase Console → Authentication → Add user with these UIDs:
       usr_admin_001
       usr_teacher_sarah
       usr_student_alex
  2. Re-run:    node firestore_seed/set_claims.js
  3. Verify:    Firestore → Data → tenants/greenwood_high/courses
EOF
