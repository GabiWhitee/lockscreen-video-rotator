#!/bin/bash
# Rota el video de la pantalla de bloqueo entre los videos de ~/Movies/FondosBloqueo.
# Se dispara al bloquear la pantalla (LaunchAgent com.gabriel.lockscreen-video-rotator).
# Los videos nuevos (.mp4/.mov/.m4v) se convierten automáticamente a HEVC 4K.
set -u

VIDEOS_DIR="$HOME/Movies/FondosBloqueo"
CONV_DIR="$VIDEOS_DIR/.converted"
STATE_FILE="$CONV_DIR/.current"
LOG="$CONV_DIR/rotator.log"
TARGET="$HOME/Library/Application Support/com.apple.wallpaper/aerials/videos/4C108785-A7BA-422E-9C79-B0129F1D5550.mov"
LOCKDIR="${TMPDIR:-/tmp}/lockscreen-rotator.lock"

mkdir -p "$CONV_DIR"

# Evitar ejecuciones simultáneas
if ! mkdir "$LOCKDIR" 2>/dev/null; then exit 0; fi
trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

shopt -s nullglob

# 1. Convertir videos nuevos o modificados
for src in "$VIDEOS_DIR"/*.mp4 "$VIDEOS_DIR"/*.mov "$VIDEOS_DIR"/*.m4v "$VIDEOS_DIR"/*.MP4 "$VIDEOS_DIR"/*.MOV; do
  name="$(basename "${src%.*}")"
  out="$CONV_DIR/$name.mov"
  if [ ! -e "$out" ] || [ "$src" -nt "$out" ]; then
    log "convirtiendo: $(basename "$src")"
    if /usr/bin/avconvert --preset PresetHEVC3840x2160 --source "$src" --output "$out" --replace >> "$LOG" 2>&1; then
      log "conversion ok: $name.mov"
    else
      log "ERROR al convertir: $(basename "$src")"
      rm -f "$out"
    fi
  fi
done

# 2. Borrar conversiones cuyo video original ya no está en la carpeta
for conv in "$CONV_DIR"/*.mov; do
  name="$(basename "${conv%.*}")"
  found=0
  for ext in mp4 mov m4v MP4 MOV; do
    if [ -e "$VIDEOS_DIR/$name.$ext" ]; then found=1; break; fi
  done
  if [ "$found" -eq 0 ]; then
    rm -f "$conv"
    log "eliminado (original borrado): $name.mov"
  fi
done

# 2b. Si está en pausa, no rotar: se queda fijo en el video actual
if [ -e "$VIDEOS_DIR/PAUSA" ]; then
  log "en PAUSA, se mantiene el video actual"
  exit 0
fi

# 3. Elegir el siguiente video (round-robin alfabético)
files=( "$CONV_DIR"/*.mov )
n=${#files[@]}
if [ "$n" -eq 0 ]; then
  log "sin videos en $VIDEOS_DIR, nada que hacer"
  exit 0
fi

current="$(cat "$STATE_FILE" 2>/dev/null || true)"
next_idx=0
for i in "${!files[@]}"; do
  if [ "$(basename "${files[$i]}")" = "$current" ]; then
    next_idx=$(( (i + 1) % n ))
    break
  fi
done
next="${files[$next_idx]}"

# Con un solo video no hay nada que rotar
if [ "$n" -eq 1 ] && [ "$(basename "$next")" = "$current" ]; then
  log "un solo video disponible, sin rotacion"
  exit 0
fi

# 4. Aplicar el video (apply-video.sh: lo alarga a ~3 min, copia atómica
# y refresca el agente de wallpaper)
if /bin/bash "$HOME/Library/Application Support/lockscreen-video-rotator/apply-video.sh" "$next"; then
  basename "$next" > "$STATE_FILE"
  log "activo: $(basename "$next")"
else
  log "ERROR al aplicar $(basename "$next")"
fi
