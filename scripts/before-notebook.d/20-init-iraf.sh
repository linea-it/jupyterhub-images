#!/bin/bash
set -e

# Inicializa o ambiente IRAF para o usuário real (KubeSpawner).
# O login.cl *upstream* usa uparm = home$uparm/ -> ~/.iraf/uparm/ antes do stty; em
# vários PVCs isso falha em uparm$pipe mesmo com o diretório criado. A LIneA instala
# /opt/linea-iraf/login.cl com uparm = $HOME/iraf/uparm/ (sempre criado aqui).

export USER="${USER:-$(whoami)}"
# Sem barra final, cl.sh resolve /usr/local/lib/irafbin/ em vez de .../iraf/bin/.
export iraf="${iraf:-/usr/local/lib/iraf/}"
export iraf="${iraf%/}/"

LINEA_IRAF_LOGIN_VER=1
# Controle de versão em ~/iraf/ (sempre gravável); ~/.iraf/ às vezes vem com dono errado na imagem/PVC.
STAMP="${HOME}/iraf/.linea_iraf_login_ver"

mkdir -p "${HOME}/.iraf/uparm" \
         "${HOME}/.iraf/imdir" \
         "${HOME}/.iraf/cache" \
         "${HOME}/iraf/uparm"

# Instala ou atualiza o login.cl patch da LIneA (incrementar LINEA_IRAF_LOGIN_VER para forçar)
if [ ! -f "$STAMP" ] || [ "$(cat "$STAMP" 2>/dev/null)" != "$LINEA_IRAF_LOGIN_VER" ]; then
  cp /opt/linea-iraf/login.cl "${HOME}/iraf/login.cl"
  echo "$LINEA_IRAF_LOGIN_VER" > "$STAMP" || true
fi

# CL usa ./login.cl no cwd; em ~ precisa de ~/login.cl -> mesmo arquivo que ~/iraf/login.cl
ln -sf "${HOME}/iraf/login.cl" "${HOME}/login.cl" 2>/dev/null || \
  cp -f "${HOME}/iraf/login.cl" "${HOME}/login.cl"

touch "${HOME}/iraf/uparm/.iraf_write_test" 2>/dev/null && rm -f "${HOME}/iraf/uparm/.iraf_write_test" || true

chmod -R u+rwX "${HOME}/.iraf" "${HOME}/iraf" 2>/dev/null || true

# Atalhos na área de trabalho
mkdir -p "${HOME}/Desktop"

DESKTOP_SRC="/opt/linea-iraf/linea-ds9-cl.desktop"
if [ -f "$DESKTOP_SRC" ]; then
  rm -f "${HOME}/Desktop/DS9-IRAF-CL.desktop" 2>/dev/null || true
  cp -f "$DESKTOP_SRC" "${HOME}/Desktop/IRAF-CL-DS9.desktop" 2>/dev/null || true
  chmod +x "${HOME}/Desktop/IRAF-CL-DS9.desktop" 2>/dev/null || true
fi

if [ -f /opt/linea-iraf/linea-saods9.desktop ]; then
  cp -f /opt/linea-iraf/linea-saods9.desktop "${HOME}/Desktop/SAOImage-DS9.desktop" 2>/dev/null || true
  chmod +x "${HOME}/Desktop/SAOImage-DS9.desktop" 2>/dev/null || true
fi

if [ -f /opt/linea-iraf/linea-topcat.desktop ]; then
  cp -f /opt/linea-iraf/linea-topcat.desktop "${HOME}/Desktop/TOPCAT.desktop" 2>/dev/null || true
  chmod +x "${HOME}/Desktop/TOPCAT.desktop" 2>/dev/null || true
fi

if [ -f /opt/linea-iraf/linea-terminal.desktop ]; then
  cp -f /opt/linea-iraf/linea-terminal.desktop "${HOME}/Desktop/Terminal.desktop" 2>/dev/null || true
  chmod +x "${HOME}/Desktop/Terminal.desktop" 2>/dev/null || true
fi
if [ -f /opt/linea-iraf/linea-xterm.desktop ]; then
  cp -f /opt/linea-iraf/linea-xterm.desktop "${HOME}/Desktop/XTerm.desktop" 2>/dev/null || true
  chmod +x "${HOME}/Desktop/XTerm.desktop" 2>/dev/null || true
fi

# Com root no arranque (ex.: KubeSpawner), os .desktop ficavam root:root → XFCE mostra cadeado
# ("lançador não confiável"). Alinhar dono ao $HOME antes de abrir o VNC.
if [ "$(id -u)" = "0" ]; then
  OWNER="$(ls -nd "$HOME" | awk '{print $3 ":" $4}')"
  chown -R "$OWNER" "${HOME}/.iraf" "${HOME}/iraf" "${HOME}/login.cl" "${HOME}/Desktop" 2>/dev/null || true
fi

chmod -R u+rwX "${HOME}/Desktop" 2>/dev/null || true
