#!/bin/bash
# Doble-click: muestra la lista de videos y te deja elegir cual poner ahora.
# El elegido queda FIJO hasta que uses "REANUDAR la rotacion".
set -u

VIDEOS_DIR="$HOME/Movies/FondosBloqueo"
CONV_DIR="$VIDEOS_DIR/.converted"
STATE_FILE="$CONV_DIR/.current"
TARGET="$HOME/Library/Application Support/com.apple.wallpaper/aerials/videos/4C108785-A7BA-422E-9C79-B0129F1D5550.mov"

cd "$VIDEOS_DIR"
shopt -s nullglob
files=( "$CONV_DIR"/*.mov )
n=${#files[@]}

if [ "$n" -eq 0 ]; then
  echo ""
  echo "  No hay videos todavia. Poné algún .mp4 en esta carpeta primero."
  echo ""
  read -r -p "  (Enter para cerrar)"
  exit 0
fi

current="$(cat "$STATE_FILE" 2>/dev/null || true)"

echo ""
echo "  ¿Qué video querés poner en la pantalla de bloqueo?"
echo ""
i=1
for f in "${files[@]}"; do
  name="$(basename "${f%.*}")"
  mark="  "
  [ "$(basename "$f")" = "$current" ] && mark="→ "   # el que está puesto ahora
  printf "  %s%2d)  %s\n" "$mark" "$i" "$name"
  i=$((i+1))
done
echo ""
echo "  (→ = el que está puesto ahora)"
echo ""
read -r -p "  Escribí el número y apretá Enter: " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$n" ]; then
  echo ""
  echo "  Número inválido. No cambié nada."
  echo ""
  read -r -p "  (Enter para cerrar)"
  exit 0
fi

chosen="${files[$((choice-1))]}"

if /bin/bash "$HOME/Library/Application Support/lockscreen-video-rotator/apply-video.sh" "$chosen"; then
  basename "$chosen" > "$STATE_FILE"
  touch "$VIDEOS_DIR/PAUSA"          # queda fijo en el elegido
  echo ""
  echo "  ✓ Listo: quedó puesto  →  $(basename "${chosen%.*}")"
  echo ""
  echo "  Queda FIJO en ese (no rota)."
  echo "  Para volver a que cambie solo: doble-click en ▶ REANUDAR la rotacion.command"
  echo ""
else
  echo ""
  echo "  Hubo un error al aplicarlo."
  echo ""
fi

read -r -p "  (Enter para cerrar)"
