# lockscreen-video-rotator

Videos propios en 4K como fondo **animado de la pantalla de bloqueo** de macOS, rotando automáticamente — con cero consumo mientras usás la Mac.

macOS no permite poner un video tuyo como fondo de pantalla. Este proyecto usa el mismo mecanismo que los "paisajes aéreos" de Apple: reemplaza el archivo de video del aéreo descargado por el tuyo. El resultado se comporta exactamente como un aéreo nativo:

- 🎬 El video se reproduce **solo en la pantalla de bloqueo**.
- 🖼️ Al desbloquear, queda un frame congelado como fondo de escritorio (sin gastar GPU ni batería).
- 🔄 En cada desbloqueo se prepara el siguiente video de tu carpeta, en ronda.

## Requisitos

- macOS 26 (Tahoe) o similar — en versiones anteriores los aéreos viven en otra ruta.
- Xcode o Command Line Tools (`xcode-select --install`) para compilar la mini-herramienta de empalme.
- Un fondo "Paisaje aéreo" elegido en **Ajustes del Sistema → Fondo de pantalla** (para que exista el archivo a reemplazar).

## Instalación

```bash
git clone https://github.com/GabiWhitee/lockscreen-video-rotator.git
cd lockscreen-video-rotator
./install.sh
```

Después tirá videos `.mp4` (idealmente 4K, por ej. de [Pexels](https://www.pexels.com/videos/)) en `~/Movies/FondosBloqueo`. Se convierten solos a HEVC y entran en la rotación.

## Uso diario

En `~/Movies/FondosBloqueo` quedan tres botones (doble-click):

| Botón | Qué hace |
|-------|----------|
| **★ ELEGIR un video** | Elegís de una lista cuál poner → queda fijo |
| **⏸ FIJAR el video actual** | Traba el que está puesto → queda fijo |
| **▶ REANUDAR la rotación** | Vuelve a cambiar de video en cada desbloqueo |

## Cómo funciona

| Pieza | Rol |
|-------|-----|
| `watcher.sh` | Agente persistente (launchd) que detecta la transición bloqueado→desbloqueado consultando `ioreg` cada 3s |
| `rotate.sh` | Convierte videos nuevos a HEVC 4K (`avconvert`), poda los borrados y elige el siguiente en ronda |
| `apply-video.sh` | Alarga el video a ~3 min y lo copia de forma atómica sobre el archivo del aéreo |
| `loop-video.swift` | Empalma el video consigo mismo vía AVFoundation, **sin re-codificar** (<1s) |

### Decisiones de diseño que costaron caro (aprendé de nuestros errores)

- **No usar `LaunchEvents`/notifyd para detectar el bloqueo**: un script de bash no puede "consumir" el evento vía XPC, y launchd lo relanza en loop infinito. Por eso el watcher hace polling de `ioreg`.
- **Rotar al desbloquear, no al bloquear**: si rotás al bloquear, la pantalla de bloqueo puede leer el archivo a medio copiar → fondo negro.
- **Alargar los videos a ~3 minutos**: los aéreos de Apple duran minutos; si tu video dura 18s, se reproduce una vez y la pantalla queda en negro. El empalme es passthrough (sin pérdida de calidad).

## Avisos

- Es un hack: pisa un archivo dentro de `~/Library/Application Support/com.apple.wallpaper/`. Una actualización de macOS puede re-descargar el aéreo original; se arregla desbloqueando una vez (la rotación lo vuelve a pisar).
- El instalador guarda un backup del aéreo original (`.mov.bak`) por si querés volver atrás.
- No cambies el fondo de pantalla en Ajustes mientras esté activo, o macOS puede forzar la re-descarga.

## Desinstalar

```bash
launchctl bootout gui/$(id -u)/com.gabriel.lockscreen-video-rotator
rm ~/Library/LaunchAgents/com.gabriel.lockscreen-video-rotator.plist
rm -rf ~/Library/Application\ Support/lockscreen-video-rotator
# restaurar el aéreo original:
cd ~/Library/Application\ Support/com.apple.wallpaper/aerials/videos
mv *.mov.bak "$(basename *.mov.bak .bak)" 2>/dev/null
killall WallpaperAgent
```
