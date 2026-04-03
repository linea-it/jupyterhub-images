#!/bin/bash
# Complementa defaults de sistema: painel pode gravar ~/.config; esconde logout no plugin “Action Buttons”.
export DISPLAY="${DISPLAY:-:1}"

wait_xfconf_session() {
  local n=0
  while [ "$n" -lt 120 ]; do
    if xfconf-query -c xfce4-session -l >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.5
    n=$((n + 1))
  done
  return 1
}

set_bool() {
  local p="$1"
  xfconf-query -c xfce4-session -p "$p" -s false -t bool 2>/dev/null || \
    xfconf-query -c xfce4-session -p "$p" -n -t bool -s false 2>/dev/null || true
}

apply_session_shutdown_keys() {
  xfconf-query -c xfce4-session -l >/dev/null 2>&1 || return 1
  # Diálogo “Sair / Encerrar sessão” do xfce4-session
  set_bool /shutdown/ShowLogout
  set_bool /shutdown/ShowSwitchUser
  return 0
}

# Plugin “Action Buttons” do painel: desliga botão de logout se existir
apply_panel_actions() {
  xfconf-query -c xfce4-panel -l >/dev/null 2>&1 || return 0
  local base ptype
  while IFS= read -r base; do
    [ -z "$base" ] && continue
    ptype="$(xfconf-query -c xfce4-panel -p "$base" 2>/dev/null | tail -1)"
    if [ "$ptype" = "actions" ]; then
      xfconf-query -c xfce4-panel -p "${base}/show-logout" -s false -t bool 2>/dev/null || \
        xfconf-query -c xfce4-panel -p "${base}/show-logout" -n -t bool -s false 2>/dev/null || true
    fi
  done < <(xfconf-query -c xfce4-panel -l 2>/dev/null | grep -E '^/plugins/plugin-[0-9]+$' || true)
}

for _ in 1 2 3 4 5 6 7 8 9 10; do
  if wait_xfconf_session && apply_session_shutdown_keys; then
    break
  fi
  sleep 0.4
done

sleep 1.5
apply_session_shutdown_keys || true
apply_panel_actions || true
