#!/bin/bash
# Copy jupyter_ai configuration (%%ai aliases, chat, linea provider) from
# /home/jovyan to $HOME when running in JupyterHub (HOME=/home/<username>).
# Locally the image uses HOME=/home/jovyan, so copying is not required.

set -e

if [ "$HOME" != "/home/jovyan" ]; then
  SRC="/home/jovyan"

  for rel in ".ipython/profile_default" ".local/share/jupyter/jupyter_ai"; do
    if [ -d "$SRC/$rel" ]; then
      mkdir -p "$HOME/$rel"
      # -n: no clobber; copy files that do not exist in destination yet
      cp -rn "$SRC/$rel"/. "$HOME/$rel/" 2>/dev/null || true
    fi
  done

  # Older profiles do not get new aliases via cp -n; append only missing ones.
  USER_IPY_CFG="$HOME/.ipython/profile_default/ipython_config.py"
  if [ -f "$USER_IPY_CFG" ]; then
    export LINEA_USER_IPY_CFG="$USER_IPY_CFG"
    python3 <<'PY'
import os

user_p = os.environ["LINEA_USER_IPY_CFG"]
with open(user_p, encoding="utf-8") as f:
    existing = f.read()

if (
    "jupyter_ai_magics" in existing
    and (
        "groq-gpt-oss-120b" not in existing
        or "nvidia-qwen2.5-coder-32b" not in existing
        or "nvidia-qwen3-coder-480b" not in existing
        or "nvidia-mistral-nemotron" not in existing

    )
):
    with open(user_p, "a", encoding="utf-8") as f:
        f.write(
            """
# OpenAI-compatible providers. In Jupyter AI settings, use:
# - GROQ_API_KEY for Groq
# - NVIDIA_API_KEY for NVIDIA
_default_aliases.update({
    "groq-gpt-oss-120b": "groq:openai/gpt-oss-120b",
    "groq-qwen3-32b": "groq:qwen/qwen3-32b",
    "groq-llama-3.3-70b": "groq:llama-3.3-70b-versatile",
    "nvidia-qwen2.5-coder-32b": "nvidia:qwen/qwen2.5-coder-32b-instruct",
    "nvidia-qwen3-coder-480b": "nvidia:qwen/qwen3-coder-480b-a35b-instruct",

})
c.AiMagics.aliases = _default_aliases
"""
        )
PY
  fi

  # cp -n does not overwrite: PVCs with old config.json miss new keys from image.
  # Merge only missing top-level user keys from the jovyan reference.
  REF_CFG="$SRC/.local/share/jupyter/jupyter_ai/config.json"
  USER_CFG="$HOME/.local/share/jupyter/jupyter_ai/config.json"
  if [ -f "$REF_CFG" ] && [ -f "$USER_CFG" ]; then
    export LINEA_REF_CFG="$REF_CFG"
    export LINEA_USER_CFG="$USER_CFG"
    python3 <<'PY'
import copy, json, os

ref_p = os.environ["LINEA_REF_CFG"]
user_p = os.environ["LINEA_USER_CFG"]
with open(ref_p, encoding="utf-8") as f:
    ref = json.load(f)
with open(user_p, encoding="utf-8") as f:
    user = json.load(f)
for k, v in ref.items():
    if k not in user:
        user[k] = copy.deepcopy(v)
# New image models (e.g., Groq in fields) without overwriting user customizations
ref_fields = ref.get("fields")
if isinstance(ref_fields, dict):
    u_fields = user.setdefault("fields", {})
    if not isinstance(u_fields, dict):
        u_fields = {}
        user["fields"] = u_fields
    for model_id, vals in ref_fields.items():
        if model_id not in u_fields:
            u_fields[model_id] = copy.deepcopy(vals)
# Obsolete key (never supported by Jupyter AI 2.x GlobalConfig)
user.pop("retriever_options", None)
with open(user_p, "w", encoding="utf-8") as f:
    json.dump(user, f, indent=4)
PY
  fi

  # If running as root (before-notebook.d), set ownership to $HOME owner
  if [ "$(id -u)" = "0" ] && [ -d "$HOME" ]; then
    OWNER="$(ls -nd "$HOME" | awk '{print $3 ":" $4}')"
    [ -d "$HOME/.ipython" ] && chown -R "$OWNER" "$HOME/.ipython"
    [ -d "$HOME/.local" ]   && chown -R "$OWNER" "$HOME/.local"
  fi
fi

# Setup do arquivo de chaves e export no processo atual.
# Importante: deve funcionar também na instância local onde HOME=/home/jovyan.
if [ -f /usr/local/bin/linea-setup-apikeys.sh ]; then
  # shellcheck disable=SC1091
  . /usr/local/bin/linea-setup-apikeys.sh
fi
