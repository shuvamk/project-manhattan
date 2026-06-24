#!/usr/bin/env bash
# Project Manhattan — bootstrap. Idempotent. Run before anything else (START.md step 1).
# Loads env, fails loud on missing REQUIRED keys, applies the spine if absent.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# 1. Load .env (your fleet delivers this out-of-band; it is gitignored — D6).
if [ -f .env ]; then
  set -a; . ./.env; set +a
else
  echo "FATAL: no .env. Pull it from your private channel (it is never committed)." >&2
  echo "       See .env.example for the required keys." >&2
  exit 1
fi

# 2. Verify REQUIRED keys — fail early and loud, never let a missing key be a silent blocker.
REQUIRED=(SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY SUPABASE_DB_URL GITHUB_TOKEN)
missing=0
for k in "${REQUIRED[@]}"; do
  if [ -z "${!k:-}" ]; then echo "FATAL: required env $k is empty." >&2; missing=1; fi
done
[ "$missing" -eq 0 ] || { echo "Fill the missing keys in .env and re-run." >&2; exit 1; }

# 3. Apply the coordination spine if it isn't there yet (idempotent — schema uses IF NOT EXISTS).
if command -v psql >/dev/null 2>&1; then
  echo "Applying spine/schema.sql ..."
  psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f spine/schema.sql >/dev/null
  echo "Spine ready."
else
  echo "WARN: psql not found — apply spine/schema.sql via the Supabase SQL editor once." >&2
fi

# 4. Sanity: confirm the control row exists (the kill switch must be reachable).
if command -v psql >/dev/null 2>&1; then
  status="$(psql "$SUPABASE_DB_URL" -tAc "select status from control where id=1" || true)"
  echo "control.status = ${status:-<unreachable>}"
fi

echo "Bootstrap complete. Role=${MANHATTAN_ROLE:-<unset>} Machine=${MANHATTAN_MACHINE:-$(hostname -s)}"
