#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "  Quest VR Link - Uninstall"
echo "=========================================="

SYSTEMD_DIR="${HOME}/.config/systemd/user"
BIN_DIR="${HOME}/.local/bin"

echo "Stopping services..."
systemctl --user stop gnirehtet.service spatial-hud.service vr-ttyd.service quest-autolaunch.service 2>/dev/null || true
systemctl --user disable gnirehtet.service spatial-hud.service vr-ttyd.service quest-autolaunch.service 2>/dev/null || true

rm -f "${SYSTEMD_DIR}/gnirehtet.service"
rm -f "${SYSTEMD_DIR}/spatial-hud.service"
rm -f "${SYSTEMD_DIR}/vr-ttyd.service"
rm -f "${SYSTEMD_DIR}/quest-autolaunch.service"
systemctl --user daemon-reload

echo "Removing binaries and HUD..."
rm -f "${BIN_DIR}/vr-screen"
rm -f "${BIN_DIR}/quest-auto-launch"
rm -f "${BIN_DIR}/quest-install-headset"
rm -f "${BIN_DIR}/quest-cleanup"
rm -rf "${HOME}/.local/share/vr-hud"
rm -rf "${HOME}/.config/quest-vr"
echo "Removing udev rule..."
if [[ -f "/etc/udev/rules.d/99-quest3.rules" ]]; then
  pkexec rm -f "/etc/udev/rules.d/99-quest3.rules"
  pkexec udevadm control --reload-rules
fi

echo "=========================================="
echo "  Desinstalado correctamente."
echo "=========================================="
