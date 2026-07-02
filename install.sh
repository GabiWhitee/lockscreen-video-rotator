#!/bin/bash
# Instalador del lockscreen-video-rotator.
# Requisitos: macOS 26+, Xcode o Command Line Tools (para compilar loop-video),
# y tener elegido un fondo de pantalla "aéreo" en Ajustes del Sistema.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$HOME/Library/Application Support/lockscreen-video-rotator"
VIDEOS_DIR="$HOME/Movies/FondosBloqueo"
PLIST="$HOME/Library/LaunchAgents/com.gabriel.lockscreen-video-rotator.plist"
AERIALS_DIR="$HOME/Library/Application Support/com.apple.wallpaper/aerials/videos"

echo "== lockscreen-video-rotator: instalación =="

# 0. Chequeos previos
if ! command -v swiftc >/dev/null; then
  echo "ERROR: falta swiftc. Instalá las Command Line Tools:  xcode-select --install" >&2
  exit 1
fi
shopt -s nullglob
aerials=( "$AERIALS_DIR"/*.mov )
if [ ${#aerials[@]} -eq 0 ]; then
  echo "AVISO: no hay ningún fondo aéreo descargado todavía."
  echo "Andá a Ajustes del Sistema → Fondo de pantalla, elegí un 'Paisaje aéreo'"
  echo "y esperá a que se descargue. Después volvé a correr este instalador."
  exit 1
fi

# 1. Copiar scripts
mkdir -p "$APP_DIR" "$VIDEOS_DIR"
cp "$REPO_DIR/src/rotate.sh" "$REPO_DIR/src/watcher.sh" "$REPO_DIR/src/apply-video.sh" "$REPO_DIR/src/loop-video.swift" "$APP_DIR/"
chmod +x "$APP_DIR"/*.sh

# 2. Compilar la herramienta de empalme
echo "Compilando loop-video..."
swiftc -O -parse-as-library "$APP_DIR/loop-video.swift" -o "$APP_DIR/loop-video"

# 3. Botones para el Finder
cp "$REPO_DIR/comandos/"*.command "$VIDEOS_DIR/"
chmod +x "$VIDEOS_DIR/"*.command

# 4. Backup del aerial original (si no existe ya)
if [ ! -e "${aerials[0]}.bak" ]; then
  cp "${aerials[0]}" "${aerials[0]}.bak"
  echo "Backup del aerial original: ${aerials[0]}.bak"
fi

# 5. LaunchAgent (vigilante de bloqueo/desbloqueo)
mkdir -p "$HOME/Library/LaunchAgents"
sed "s|__HOME__|$HOME|g" "$REPO_DIR/launchagent/com.gabriel.lockscreen-video-rotator.plist.template" > "$PLIST"
launchctl bootout "gui/$(id -u)/com.gabriel.lockscreen-video-rotator" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo ""
echo "✓ Listo. Tirá videos .mp4 (idealmente 4K) en:  $VIDEOS_DIR"
echo "  En cada desbloqueo se prepara el siguiente video para la pantalla de bloqueo."
echo "  Botones en esa carpeta: ★ ELEGIR / ⏸ FIJAR / ▶ REANUDAR."
