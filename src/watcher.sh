#!/bin/bash
# Vigila el estado real de la pantalla de bloqueo y, en la transición
# bloqueado -> desbloqueado, dispara la rotación del video (rotate.sh):
# así el siguiente video queda preparado con tiempo y la pantalla de bloqueo
# nunca carga un archivo que se está escribiendo (causaba fondo negro).
# Corre como agente persistente (RunAtLoad + KeepAlive), sin LaunchEvents:
# esos no funcionan con scripts porque hay que "consumir" el evento vía XPC.
set -u

DIR="$HOME/Library/Application Support/lockscreen-video-rotator"
LOG="$HOME/Movies/FondosBloqueo/.converted/rotator.log"
POLL=3   # segundos entre chequeos

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [watcher] $*" >> "$LOG"; }

is_locked() {
  ioreg -n Root -d1 -a 2>/dev/null | grep -q CGSSessionScreenIsLocked
}

log "iniciado (poll ${POLL}s)"
prev=0
while true; do
  if is_locked; then cur=1; else cur=0; fi
  if [ "$cur" = "0" ] && [ "$prev" = "1" ]; then
    log "transicion -> DESBLOQUEADO, preparo el siguiente video"
    sleep 5   # dejar que el escritorio termine de cargar tranquilo
    /bin/bash "$DIR/rotate.sh"
  fi
  prev="$cur"
  sleep "$POLL"
done
