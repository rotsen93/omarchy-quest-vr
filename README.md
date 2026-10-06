# Quest VR Link for Omarchy (`makiaveloh.quest-vr`)

Una suite completa y modular para integrar el **Meta Quest 3** con **Omarchy Linux / Hyprland**:
streaming de ultra baja latencia por cable USB (reverse tethering), monitor virtual **Ultrawide 32:9 (3840x1080@90Hz)**, auto-lanzador inteligente y un **Spatial HUD flotante** para realidad mixta (Passthrough).

---

## Características

- 󰄛 **Widget nativo de barra en Omarchy (Quickshell)**:
  - Telemetría en vivo del visor: nivel de batería, estado de transmisión y túnel USB.
  - Alternador con un solo clic o atajo (`SUPER + ALT + V`) entre monitor físico 16:9 y **Ultrawide virtual 32:9**.
  - Lanzadores directos para Moonlight XR y Spatial HUD en el visor vía ADB.
- 🔌 **Streaming por cable sin latencia ni dependencia de Wi-Fi**:
  - Reverse tethering automático vía **Gnirehtet** sobre ADB (`10.0.2.2`).
  - Túnel transparente con soporte total para paquetes UDP de video/audio.
- 🚀 **Auto-lanzador por hardware (udev)**:
  - Al enchufar el cable USB, el sistema detecta el visor y abre automáticamente el Spatial HUD en el navegador y Moonlight XR.
- 🌌 **Spatial HUD (Realidad Mixta / Passthrough)**:
  - Panel web flotante con tema translúcido oscuro (`http://10.0.2.2:9090`):
    1. **Métricas de PC**: CPU, temperatura, RAM y consumo en Watts de la batería del ThinkPad.
    2. **Terminal interactiva**: Embebida con `ttyd` (puerto 7681) y barra de teclas táctiles (`Ctrl`, `Alt`, `Esc`, `Tab`, `^C`, `^D`, flechas direccionales).
    3. **Pomodoro espacial**: Temporizador de enfoque (25m / 5m) con controles táctiles en VR.
    4. **Notificaciones**: Interceptor en tiempo real de alertas de escritorio vía D-Bus.

---

## Arquitectura

```
  [ Meta Quest 3 ]                                        [ PC / Hyprland ]
┌────────────────────────┐                             ┌─────────────────────────┐
│ Moonlight XR (Video)   │ ◄─── UDP Stream (VA-API) ───┤ Sunshine (eDP-1/HEADLESS│
│ Quest Browser (HUD)    │ ◄─── HTTP (10.0.2.2:9090) ──┤ Spatial HUD Server      │
│ App Gnirehtet (VPN)    │ ◄─── Túnel USB / ADB ───────┤ Gnirehtet Daemon        │
└────────────────────────┘                             └─────────────────────────┘
```

---

## Requisitos

- **OS**: Omarchy 4 (Quattro) / Arch Linux con Hyprland.
- **Hardware**: Meta Quest 3 conectado vía cable USB-C con *Depuración USB* habilitada.
- **Paquetes**: `sunshine`, `libva-utils`, `ttyd`, `android-tools`.

---

## Instalación

### 1. Clonar el repositorio
```bash
git clone https://github.com/makiaveloh/omarchy-quest-vr.git
cd omarchy-quest-vr
```

### 2. Ejecutar el instalador
```bash
./install.sh
```

### 3. Registrar el widget en tu barra
Edita `~/.config/omarchy/shell.json` y añade `"makiaveloh.quest-vr"` a la sección deseada:
```json
{
  "bar": {
    "layout": {
      "right": [
        { "id": "makiaveloh.quest-vr" }
      ]
    }
  }
}
```

Reinicia el shell de Omarchy:
```bash
omarchy restart shell
```

---

## En el Visor (Meta Quest 3)

1. **Instalar Moonlight XR**:
   - Descarga el APK de [Moonlight XR Releases](https://github.com/Gilleece/moonlight-android-xr/releases) e instálalo con:
     ```bash
     adb install moonlight_XR_v0.4.2.apk
     ```
2. **Conectar**:
   - Conecta el cable USB a la laptop y acepta el diálogo de **Conexión VPN** la primera vez.
   - En Moonlight añade el equipo con la IP `10.0.2.2`.
   - Empareja el PIN en `https://localhost:47990` en tu PC.

---

## Desinstalación limpia

Para retirar el plugin y todos sus servicios sin dejar residuos:
```bash
./uninstall.sh
```

---

## Licencia

Distribuido bajo la licencia [MIT](LICENSE).
