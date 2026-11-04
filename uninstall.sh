#!/usr/bin/env bash
# Removes the conky-dashboard widget for the current user (asks first).
set -euo pipefail
INSTALL_DIR="${CONKY_DASHBOARD_DIR:-$HOME/.config/conky-dashboard}"
AUTOSTART_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/autostart/conky-dashboard.desktop"

echo "This will stop the widget and remove:"
echo "  $INSTALL_DIR"
echo "  $AUTOSTART_FILE"
read -r -p "Continue? [y/N] " ans
[ "${ans,,}" = "y" ] || { echo "Cancelled."; exit 0; }

pkill -f "conky -c $INSTALL_DIR/dashboard.conkyrc" 2>/dev/null || true
rm -rf -- "$INSTALL_DIR"
rm -f -- "$AUTOSTART_FILE"
echo "Removed. (conky and the other packages were left installed.)"
