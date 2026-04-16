#!/bin/bash
# Ensure $HOME/.linea/apikeys.env exists (0600) and make sure the current
# shell and interactive shells load the keys.

set -e

API_KEYS_DIR="$HOME/.linea"
API_KEYS_FILE="$API_KEYS_DIR/apikeys.env"

mkdir -p "$API_KEYS_DIR"

if [ ! -f "$API_KEYS_FILE" ]; then
  cat >"$API_KEYS_FILE" <<'EOF'
# Add your keys below and then run:
# source "$HOME/.linea/apikeys.env"
OPENAI_API_KEY=""
GROQ_API_KEY=""
NVIDIA_API_KEY=""
ANTHROPIC_API_KEY=""
GOOGLE_API_KEY=""
EOF
  chmod 600 "$API_KEYS_FILE"
fi

# If running as root (common for before-notebook.d), ensure the owner matches
# the real $HOME owner (so Jupyter Server can read the file).
if [ "$(id -u)" = "0" ] && [ -d "$HOME" ]; then
  OWNER="$(ls -nd "$HOME" | awk '{print $3 ":" $4}')"
  # Tighten directory permissions while keeping it accessible to the owner.
  chmod 700 "$API_KEYS_DIR" 2>/dev/null || true
  chown -R "$OWNER" "$API_KEYS_DIR"
fi

# Export into the current process (used by JupyterLab/jupyter-ai processes).
if [ -f /usr/local/bin/linea-load-apikeys.sh ]; then
  # shellcheck disable=SC1091
  . /usr/local/bin/linea-load-apikeys.sh
fi

# Ensure interactive shells auto-load keys from the helper.
BASHRC_FILE="$HOME/.bashrc"
touch "$BASHRC_FILE"

if ! grep -Fq ">>> linea api keys >>>" "$BASHRC_FILE"; then
  cat >>"$BASHRC_FILE" <<'EOF'

# >>> linea api keys >>>
# User-managed API keys file for Jupyter terminals/sessions.
if [ -f "/usr/local/bin/linea-load-apikeys.sh" ]; then
  # shellcheck disable=SC1091
  . "/usr/local/bin/linea-load-apikeys.sh"
fi
alias linea-source-keys='source "/usr/local/bin/linea-load-apikeys.sh"'
# <<< linea api keys <<<
EOF
fi
