#!/bin/bash
# Fundo sólido do xfdesktop (XFCE no VNC): #1B2C63
# + tamanho dos ícones + tema Adwaita (lançadores .desktop com ícones temáticos escalam melhor)
# + ocultar ícones nativos Home / File System (só ficam os atalhos em ~/Desktop).
# Executado no autostart; pode repetir porque os canais xfconf aparecem após o xfdesktop.

LINEA_R=0.10588235294117647
LINEA_G=0.17254901960784313
LINEA_B=0.38823529411764707
LINEA_A=1.0

_apply_linea_desktop_bg() {
  xfconf-query -c xfce4-desktop -l >/dev/null 2>&1 || return 1

  while IFS= read -r p; do
    [ -z "$p" ] && continue
    xfconf-query -c xfce4-desktop -p "$p" -s '' -t string 2>/dev/null || true
  done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep last-image || true)

  while IFS= read -r p; do
    [ -z "$p" ] && continue
    xfconf-query -c xfce4-desktop -p "$p" -s 0 -t int 2>/dev/null || \
    xfconf-query -c xfce4-desktop -p "$p" -n -t int -s 0 2>/dev/null || true
  done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/workspace[0-9]+/image-style$' || true)

  while IFS= read -r p; do
    [ -z "$p" ] && continue
    xfconf-query -c xfce4-desktop -p "$p" -s 0 -t int 2>/dev/null || \
    xfconf-query -c xfce4-desktop -p "$p" -n -t int -s 0 2>/dev/null || true
  done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/workspace[0-9]+/color-style$' || true)

  while IFS= read -r p; do
    [ -z "$p" ] && continue
    xfconf-query -c xfce4-desktop -p "$p" -t double -s "$LINEA_R" -t double -s "$LINEA_G" -t double -s "$LINEA_B" -t double -s "$LINEA_A" 2>/dev/null || \
    xfconf-query -c xfce4-desktop -p "$p" -n -t double -s "$LINEA_R" -t double -s "$LINEA_G" -t double -s "$LINEA_B" -t double -s "$LINEA_A" 2>/dev/null || true
  done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/workspace[0-9]+/rgba1$' || true)

  LINEA_DESKTOP_ICON_SIZE=64
  xfconf-query -c xfce4-desktop -p /desktop-icons/icon-size -s "$LINEA_DESKTOP_ICON_SIZE" -t uint 2>/dev/null || \
  xfconf-query -c xfce4-desktop -p /desktop-icons/icon-size -n -t uint -s "$LINEA_DESKTOP_ICON_SIZE" 2>/dev/null || \
  xfconf-query -c xfce4-desktop -p /desktop-icons/icon-size -s "$LINEA_DESKTOP_ICON_SIZE" -t int 2>/dev/null || \
  xfconf-query -c xfce4-desktop -p /desktop-icons/icon-size -n -t int -s "$LINEA_DESKTOP_ICON_SIZE" 2>/dev/null || true

  for _key in show-home show-filesystem; do
    _p="/desktop-icons/file-icons/${_key}"
    xfconf-query -c xfce4-desktop -p "$_p" -n -t bool -s false 2>/dev/null || \
      xfconf-query -c xfce4-desktop -p "$_p" -s false -t bool 2>/dev/null || true
  done

  if xfconf-query -c xsettings -l >/dev/null 2>&1; then
    xfconf-query -c xsettings -p /Net/IconThemeName -s Adwaita -t string 2>/dev/null || \
      xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s Adwaita 2>/dev/null || true
  fi
}

for _ in 1 2 3 4 5 6 7 8 9 10; do
  if _apply_linea_desktop_bg; then
    break
  fi
  sleep 0.4
done

sleep 1.5
_apply_linea_desktop_bg || true
sleep 3
_apply_linea_desktop_bg || true
