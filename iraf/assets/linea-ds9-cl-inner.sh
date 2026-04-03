#!/bin/bash
# Sessão dentro do xterm: DS9 em segundo plano e CL no primeiro plano.
export USER="${USER:-$(id -un)}"
export TERM="${TERM:-xterm}"
export iraf="${iraf:-/usr/local/lib/iraf/}"
export iraf="${iraf%/}/"

if [ ! -f "${HOME}/iraf/login.cl" ]; then
  bash /usr/local/bin/before-notebook.d/20-init-iraf.sh
fi
cd "${HOME}/iraf" || exit 1

if command -v ds9 >/dev/null 2>&1; then
  ds9 &
else
  echo "ds9 não encontrado no PATH." >&2
fi

exec cl
