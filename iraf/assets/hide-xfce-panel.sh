#!/bin/bash
# Oculta a barra de tarefas do XFCE (painel inferior) no desktop VNC.
# Usa autohide via xfconf; se não existir canal/propriedade, termina o painel.

export DISPLAY="${DISPLAY:-:1}"

wait_xfconf() {
  local n=0
  while [ "$n" -lt 120 ]; do
    if xfconf-query -c xfce4-panel -l >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.5
    n=$((n + 1))
  done
  return 1
}

wait_xfconf || exit 0

set_autohide() {
  local base="$1"
  xfconf-query -c xfce4-panel -p "${base}/autohide" -n -t bool -s true 2>/dev/null || \
  xfconf-query -c xfce4-panel -p "${base}/autohide" -s true -t bool 2>/dev/null || return 1
  # 2 = always autohide (comportamento mais previsível no VNC)
  xfconf-query -c xfce4-panel -p "${base}/autohide-behavior" -n -t int -s 2 2>/dev/null || \
  xfconf-query -c xfce4-panel -p "${base}/autohide-behavior" -s 2 -t int 2>/dev/null || true
  return 0
}

ok=false
# Painel padrão: panel-1; tenta também panel-2 (multi-monitor / perfis)
for pid in panel-1 panel-2; do
  if set_autohide "/panels/${pid}"; then
    ok=true
  fi
done

if [ "$ok" != true ]; then
  # Sem xfconf utilizável: encerra o painel para liberar espaço
  sleep 1
  xfce4-panel -q 2>/dev/null || true
fi
