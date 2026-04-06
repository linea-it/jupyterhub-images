#!/bin/bash
# Copia a configuração do jupyter_ai (aliases %%ai, chat, linea provider) de
# /home/jovyan para $HOME quando o servidor roda no JupyterHub (HOME=/home/<username>).
# Localmente a imagem usa HOME=/home/jovyan, então não é necessário copiar.

set -e

if [ "$HOME" != "/home/jovyan" ]; then
  SRC="/home/jovyan"

  for rel in ".ipython/profile_default" ".local/share/jupyter/jupyter_ai"; do
    if [ -d "$SRC/$rel" ]; then
      mkdir -p "$HOME/$rel"
      # -n: no clobber; copia ficheiros que ainda não existem no destino
      cp -rn "$SRC/$rel"/. "$HOME/$rel/" 2>/dev/null || true
    fi
  done

  # cp -n não sobrescreve: PVCs com config.json antigo não ganham chaves novas da imagem.
  # Mescla só chaves de topo em falta no utilizador a partir da referência em jovyan.
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
# Novos modelos na imagem (ex. Groq em fields) sem sobrescrever customizações do utilizador
ref_fields = ref.get("fields")
if isinstance(ref_fields, dict):
    u_fields = user.setdefault("fields", {})
    if not isinstance(u_fields, dict):
        u_fields = {}
        user["fields"] = u_fields
    for model_id, vals in ref_fields.items():
        if model_id not in u_fields:
            u_fields[model_id] = copy.deepcopy(vals)
# Chave obsoleta (nunca suportada pelo GlobalConfig do Jupyter AI 2.x)
user.pop("retriever_options", None)
with open(user_p, "w", encoding="utf-8") as f:
    json.dump(user, f, indent=4)
PY
  fi

  # Se rodando como root (before-notebook.d), ajustar dono para o dono do $HOME
  if [ "$(id -u)" = "0" ] && [ -d "$HOME" ]; then
    OWNER="$(ls -nd "$HOME" | awk '{print $3 ":" $4}')"
    [ -d "$HOME/.ipython" ] && chown -R "$OWNER" "$HOME/.ipython"
    [ -d "$HOME/.local" ]   && chown -R "$OWNER" "$HOME/.local"
  fi
fi
