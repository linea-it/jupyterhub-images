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

  # Se rodando como root (before-notebook.d), ajustar dono para o dono do $HOME
  if [ "$(id -u)" = "0" ] && [ -d "$HOME" ]; then
    OWNER="$(ls -nd "$HOME" | awk '{print $3 ":" $4}')"
    [ -d "$HOME/.ipython" ] && chown -R "$OWNER" "$HOME/.ipython"
    [ -d "$HOME/.local" ]   && chown -R "$OWNER" "$HOME/.local"
  fi
fi
