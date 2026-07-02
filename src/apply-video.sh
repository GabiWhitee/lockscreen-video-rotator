#!/bin/bash
# Aplica un video (ya convertido a HEVC) como fondo de pantalla de bloqueo:
# 1) lo alarga a ~3 min empalmándolo consigo mismo (los videos cortos
#    terminaban y dejaban la pantalla de bloqueo en negro),
# 2) lo copia de forma atómica (temp + rename) al archivo del aerial,
# 3) refresca el agente de wallpaper.
# Uso: apply-video.sh <video-convertido.mov>
set -u

DIR="$HOME/Library/Application Support/lockscreen-video-rotator"
MIN_SECONDS=180

# Detectar el aerial descargado a pisar (el UUID varía según la Mac:
# es el fondo aéreo que el usuario tenga elegido en Ajustes del Sistema)
AERIALS_DIR="$HOME/Library/Application Support/com.apple.wallpaper/aerials/videos"
TARGET=""
for f in "$AERIALS_DIR"/*.mov; do
  [ -e "$f" ] && TARGET="$f" && break
done
if [ -z "$TARGET" ]; then
  echo "no hay ningún aerial descargado: elegí un fondo aéreo en Ajustes del Sistema primero" >&2
  exit 1
fi

src="${1:?uso: apply-video.sh <video.mov>}"
tmp="$TARGET.tmp.$$"

if "$DIR/loop-video" "$src" "$tmp" "$MIN_SECONDS" >/dev/null 2>&1; then
  :
else
  # si el empalme falla, usar el video tal cual antes que no poner nada
  cp "$src" "$tmp" || { rm -f "$tmp"; exit 1; }
fi

chmod 600 "$tmp" && mv -f "$tmp" "$TARGET" || { rm -f "$tmp"; exit 1; }
killall WallpaperAgent 2>/dev/null
exit 0
