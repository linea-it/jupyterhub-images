#!/bin/sh
# Substitui xfce4-session-logout no desktop VNC: encerrar sessão deixa o utilizador sem forma fiável de voltar.
export DISPLAY="${DISPLAY:-:1}"
if command -v zenity >/dev/null 2>&1; then
  zenity --info --title="Sessão" --text="Encerrar sessão não está disponível neste ambiente remoto." 2>/dev/null || true
elif command -v xmessage >/dev/null 2>&1; then
  xmessage -center "Encerrar sessão não está disponível neste ambiente remoto." 2>/dev/null || true
fi
exit 1
