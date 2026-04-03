#!/bin/bash
# Teste não interativo do CL (CI / docker compose exec). Idempotente com 20-init-iraf.sh.
set -euo pipefail

export USER="${USER:-$(id -un)}"
export TERM="${TERM:-dumb}"
export iraf="${iraf:-/usr/local/lib/iraf/}"
export iraf="${iraf%/}/"

/usr/local/bin/before-notebook.d/20-init-iraf.sh

cd "${HOME}/iraf"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

set +e
printf 'logout\n' | cl >"$tmp" 2>&1
cl_rc="${PIPESTATUS[1]}"
set -e

if grep -q "Fatal startup error" "$tmp" \
  || grep -q "Environment variable 'USER' not found" "$tmp" \
  || grep -q "Environment variable 'TERM' not found" "$tmp" \
  || grep -q "irafbin/ecl.e" "$tmp"; then
  cat "$tmp" >&2
  exit 1
fi

if ! grep -q "Community IRAF" "$tmp"; then
  echo "test-iraf-cl: saída inesperada do cl (rc=$cl_rc):" >&2
  cat "$tmp" >&2
  exit 1
fi

if [ "$cl_rc" != 0 ]; then
  echo "test-iraf-cl: cl saiu com código $cl_rc" >&2
  cat "$tmp" >&2
  exit 1
fi

echo "test-iraf-cl: OK (CL)"

# PyRAF exige USER no ambiente (como o CL); o kernel do Jupyter herda USER do start.sh.
python - <<'PY' || exit 1
from pyraf import iraf  # noqa: F401

print("test-iraf-cl: OK (PyRAF)")
PY
