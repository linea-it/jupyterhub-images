#!/bin/bash
# Load LineA API keys from $HOME/.linea/apikeys.env into the current shell.
#
# This script is intended to be *sourced* (via `source` / `. script.sh`) so that
# `export` affects the calling process.
#
# It avoids clobbering already-defined environment variables: if the env var
# already exists and `apikeys.env` has an empty value, we keep the existing one.

set -e

API_KEYS_FILE="${HOME}/.linea/apikeys.env"

API_KEYS_VARS=(
  OPENAI_API_KEY
  GROQ_API_KEY
  NVIDIA_API_KEY
  ANTHROPIC_API_KEY
  GOOGLE_API_KEY
)

declare -A LINEA_PREV_KEYS
for var in "${API_KEYS_VARS[@]}"; do
  # Capture previous values from the calling shell.
  LINEA_PREV_KEYS["$var"]="${!var-}"
done

if [ -f "$API_KEYS_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$API_KEYS_FILE"
  set +a
fi

for var in "${API_KEYS_VARS[@]}"; do
  val="${!var-}"
  if [ -n "$val" ]; then
    export "${var}=${val}"
  elif [ -n "${LINEA_PREV_KEYS[$var]}" ]; then
    export "${var}=${LINEA_PREV_KEYS[$var]}"
  fi
done
