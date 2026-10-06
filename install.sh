#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "  Quest VR Link - Setup & Installer"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
SYSTEMD_DIR="${HOME}/.config/systemd/user"
HUD_DIR="${HOME}/.local/share/vr-hud"
GNIREHTET_DIR="${HOME}/.local/share/gnirehtet"

mkdir -p "${BIN_DIR}" "${SYSTEMD_DIR}" "${HUD_DIR}" "${GNIREHTET_DIR}"

echo "[1/6] Installing dependencies..."
pkexec pacman -S --needed --noconfirm sunshine libva-utils ttyd android-tools

echo "[2/6] Installing helper scripts..."
cp "${SCRIPT_DIR}/bin/vr-screen" "${BIN_DIR}/vr-screen"
cp "${SCRIPT_DIR}/bin/quest-auto-launch" "${BIN_DIR}/quest-auto-launch"
cp "${SCRIPT_DIR}/bin/quest-install-headset" "${BIN_DIR}/quest-install-headset"
chmod +x "${BIN_DIR}/vr-screen" "${BIN_DIR}/quest-auto-launch" "${BIN_DIR}/quest-install-headset"

echo "[3/6] Setting up Spatial HUD server..."
cp -r "${SCRIPT_DIR}/hud/"* "${HUD_DIR}/"
chmod +x "${HUD_DIR}/server.py"

echo "[4/6] Setting up systemd user services..."
cp "${SCRIPT_DIR}/systemd/"*.service "${SYSTEMD_DIR}/"
systemctl --user daemon-reload
systemctl --user enable --now gnirehtet.service spatial-hud.service vr-ttyd.service app-dev.lizardbyte.app.Sunshine.service

echo "[5/6] Setting up udev rules for auto-launch..."
pkexec cp "${SCRIPT_DIR}/udev/99-quest3.rules" /etc/udev/rules.d/99-quest3.rules
pkexec udevadm control --reload-rules

echo "[6/6] Checking Gnirehtet binaries..."
if [[ ! -f "${GNIREHTET_DIR}/gnirehtet" ]]; then
  echo "Downloading Gnirehtet v2.5.1..."
  TMP_GNI="/tmp/gnirehtet_install"
  mkdir -p "${TMP_GNI}"
  curl -sL -o "${TMP_GNI}/gnirehtet.zip" "https://github.com/Genymobile/gnirehtet/releases/download/v2.5.1/gnirehtet-rust-linux64-v2.5.1.zip"
  unzip -q -o "${TMP_GNI}/gnirehtet.zip" -d "${TMP_GNI}"
  cp "${TMP_GNI}/gnirehtet-rust-linux64/"* "${GNIREHTET_DIR}/"
  ln -sf "${GNIREHTET_DIR}/gnirehtet" "${BIN_DIR}/gnirehtet"
  rm -rf "${TMP_GNI}"
fi

echo "=========================================="
echo "  Instalación completada exitosamente!"
echo "  Agrega el widget en ~/.config/omarchy/shell.json:"
echo "    {\"id\": \"makiaveloh.quest-vr\"}"
echo "=========================================="
