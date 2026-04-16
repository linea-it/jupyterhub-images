#!/bin/bash
# Load LineA API keys from $HOME/.linea/apikeys.env into the current shell.
#
# This script is intended to be *sourced* (via `source` / `. script.sh`) so that
# `export` affects the calling process.
#
# It avoids clobbering already-defined environment variables: if the env var
# already exists and `apikeys.env` has an empty value, we keep the existing one.
# It also ignores invalid/non-assignment lines instead of executing them.

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
declare -A LINEA_FILE_KEYS
for var in "${API_KEYS_VARS[@]}"; do
  # Capture previous values from the calling shell.
  LINEA_PREV_KEYS["$var"]="${!var-}"
done

if [ -f "$API_KEYS_FILE" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    # Accept: KEY=VALUE or export KEY=VALUE (with optional surrounding spaces).
    if [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      key="${BASH_REMATCH[2]}"
      raw_val="${BASH_REMATCH[3]}"

      # Keep only the API key variables managed by this helper.
      keep_var="false"
      for allowed in "${API_KEYS_VARS[@]}"; do
        if [ "$key" = "$allowed" ]; then
          keep_var="true"
          break
        fi
      done
      [ "$keep_var" = "true" ] || continue

      # Trim spaces around the value.
      raw_val="${raw_val#"${raw_val%%[![:space:]]*}"}"
      raw_val="${raw_val%"${raw_val##*[![:space:]]}"}"

      # Remove one layer of surrounding quotes, if present.
      if [[ "$raw_val" =~ ^\"(.*)\"$ ]]; then
        parsed_val="${BASH_REMATCH[1]}"
      elif [[ "$raw_val" =~ ^\'(.*)\'$ ]]; then
        parsed_val="${BASH_REMATCH[1]}"
      else
        parsed_val="$raw_val"
      fi

      LINEA_FILE_KEYS["$key"]="$parsed_val"
    fi
  done < "$API_KEYS_FILE"
fi

for var in "${API_KEYS_VARS[@]}"; do
  if [ "${LINEA_FILE_KEYS[$var]+x}" = "x" ]; then
    val="${LINEA_FILE_KEYS[$var]}"
  else
    val=""
  fi

  if [ -n "$val" ]; then
    export "${var}=${val}"
  elif [ -n "${LINEA_PREV_KEYS[$var]}" ]; then
    export "${var}=${LINEA_PREV_KEYS[$var]}"
  fi
done
