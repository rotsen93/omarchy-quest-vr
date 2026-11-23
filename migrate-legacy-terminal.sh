#!/bin/bash
set -euo pipefail

unit=vr-ttyd.service
unit_path="${HOME}/.config/systemd/user/${unit}"
client_path="${HOME}/.local/share/vr-hud/custom_ttyd.html"

load_state=$(systemctl --user show --property=LoadState --value "$unit") || {
  [[ "$load_state" == "not-found" ]] || exit 1
}
if [[ "$load_state" != "not-found" ]]; then
  systemctl --user disable --now "$unit"
fi

if [[ -e "$unit_path" || -L "$unit_path" ]]; then
  rm -f -- "$unit_path"
  systemctl --user daemon-reload
fi
rm -f -- "$client_path"
