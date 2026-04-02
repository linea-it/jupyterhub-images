#!/bin/bash
# Fetches latest tutorials from the remote repo and syncs them to the
# user's home.  Falls back to the version baked into the image when the
# network is unreachable.  welcome.html is always overwritten with the
# newest copy from the fetch (or from image cache if the fetch failed).
set -e

REPO="${TUTORIALS_REPO:-https://github.com/linea-it/jupyterhub-tutorial}"
BRANCH="${TUTORIALS_BRANCH:-main}"
STAGING="/opt/linea-tutorials"
TEMPLATES="/opt/notebook-templates"
TARGET="$HOME/notebooks/tutorials"

# --- 1) Fetch latest tutorials from remote ---------------------------------
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL_URL="${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

if curl -fsSL --connect-timeout 5 --max-time 30 "$TARBALL_URL" \
     | tar xz --strip-components=2 -C "$TMP_DIR" \
         "jupyterhub-tutorial-${BRANCH}/tutorials/" 2>/dev/null; then

  # Update staging area and notebook-templates if writable (root)
  if [ -w "$STAGING" ]; then
    rm -rf "${STAGING:?}"/*
    cp -a "$TMP_DIR"/. "$STAGING/"
    rm -rf "${TEMPLATES:?}"/*
    cp -a "$TMP_DIR"/. "$TEMPLATES/"
    rm -f "$TEMPLATES/welcome.html"
    chmod -R a+rX "$STAGING" "$TEMPLATES"
  fi

  SRC="$TMP_DIR"
  echo "10-init-tutorials: updated from ${REPO} (branch: ${BRANCH})"
else
  SRC="$STAGING"
  echo "10-init-tutorials: fetch failed, using cached version"
fi

# --- 2) Sync tutorials to user's home directory ----------------------------
# -rn: copy only missing files, never overwrite user edits (except welcome.html)
mkdir -p "$TARGET"
cp -rn "$SRC"/. "$TARGET/"
# welcome.html: sempre substituir pela versão mais recente disponível em $SRC
# (tarball recém-baixado ou cópia em cache na imagem após fetch falhar).
if [ -f "$SRC/welcome.html" ]; then
  cp -f "$SRC/welcome.html" "$TARGET/welcome.html"
fi

# --- 3) Fix ownership and permissions -------------------------------------
if [ "$(id -u)" = "0" ]; then
  OWNER="$(ls -nd "$HOME" | awk '{print $3 ":" $4}')"
  chown -R "$OWNER" "$TARGET"
fi
chmod -R u+rwX "$TARGET"
