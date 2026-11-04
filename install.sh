#!/usr/bin/env bash
# Installs the conky-dashboard widget for the current user.
# Usage: ./install.sh [--no-deps] [--no-autostart] [--no-start]
#                     [--footer "text"] [--alignment top_right] [--cores N]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${CONKY_DASHBOARD_DIR:-$HOME/.config/conky-dashboard}"
AUTOSTART_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/autostart/conky-dashboard.desktop"

DO_DEPS=1 DO_AUTOSTART=1 DO_START=1
FOOTER="© Rincol Tech Solutions"
ALIGNMENT="top_right"
CORES=""

while [ $# -gt 0 ]; do
  case "$1" in
    --no-deps)      DO_DEPS=0 ;;
    --no-autostart) DO_AUTOSTART=0 ;;
    --no-start)     DO_START=0 ;;
    --footer)       FOOTER="${2-}"; shift ;;
    --alignment)    ALIGNMENT="${2-}"; shift ;;
    --cores)        CORES="${2-}"; shift ;;
    -h|--help)      sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

say() { printf '==> %s\n' "$*"; }

# ── 1. System packages from requirements.txt ────────────────────────────────
mapfile -t PKGS < <(sed 's/#.*//' "$REPO_DIR/requirements.txt" | awk 'NF{print $1}')
if [ "$DO_DEPS" = 1 ]; then
  MISSING=()
  if command -v dpkg >/dev/null 2>&1; then
    for p in "${PKGS[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || MISSING+=("$p"); done
    if [ ${#MISSING[@]} -gt 0 ]; then
      say "Installing missing packages: ${MISSING[*]}"
      sudo apt-get update -qq
      sudo apt-get install -y "${MISSING[@]}"
    else
      say "All required packages are already installed"
    fi
  else
    say "This is not a Debian-based system. Install these yourself, then re-run with --no-deps:"
    printf '    %s\n' "${PKGS[@]}"
    exit 1
  fi
fi
command -v conky >/dev/null 2>&1 || { echo "conky is not installed." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is not installed." >&2; exit 1; }

if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
  say "WARNING: you are on Wayland. Conky's desktop-window mode works best on X11; the widget may not show."
fi

# ── 2. Detect this machine's hardware ────────────────────────────────────────
WIFI_IFACE="none"
for d in /sys/class/net/*/wireless; do [ -d "$d" ] && { WIFI_IFACE="$(basename "$(dirname "$d")")"; break; }; done

ETH_IFACE="none"
for n in /sys/class/net/*; do
  b="$(basename "$n")"
  case "$b" in en*|eth*) [ -e "$n/device" ] && [ ! -d "$n/wireless" ] && { ETH_IFACE="$b"; break; } ;; esac
done

BATTERY="BAT0"
for b in /sys/class/power_supply/BAT*; do [ -e "$b" ] && { BATTERY="$(basename "$b")"; break; }; done

# Pick the CPU temperature sensor by name (hwmon numbers change between boots/machines).
TEMP_DEV=""
for want in coretemp k10temp zenpower cpu_thermal acpitz; do
  for h in /sys/class/hwmon/hwmon*; do
    [ "$(cat "$h/name" 2>/dev/null)" = "$want" ] && { TEMP_DEV="$want"; break 2; }
  done
done
[ -n "$TEMP_DEV" ] || TEMP_DEV="0"

NPROC="$(nproc)"
[ -n "$CORES" ] || CORES=$(( NPROC > 8 ? 8 : NPROC ))

say "Detected: wifi=$WIFI_IFACE ethernet=$ETH_IFACE battery=$BATTERY temp-sensor=$TEMP_DEV cores-shown=$CORES"

# ── 3. Render the config ─────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
install -m 755 "$REPO_DIR/dashboard/fact.sh" "$INSTALL_DIR/fact.sh"
# Keep an existing facts.txt so facts the widget already fetched are not lost.
[ -e "$INSTALL_DIR/facts.txt" ] || install -m 644 "$REPO_DIR/dashboard/facts.txt" "$INSTALL_DIR/facts.txt"

REPO_DIR="$REPO_DIR" INSTALL_DIR="$INSTALL_DIR" WIFI_IFACE="$WIFI_IFACE" ETH_IFACE="$ETH_IFACE" \
BATTERY="$BATTERY" TEMP_DEV="$TEMP_DEV" CORES="$CORES" FOOTER="$FOOTER" ALIGNMENT="$ALIGNMENT" \
python3 - <<'PY'
import os
e = os.environ
text = open(os.path.join(e["REPO_DIR"], "dashboard", "dashboard.conkyrc.template"), encoding="utf-8").read()

cpu = "\n".join(
    f"${{color3}}  Core {i}: ${{color6}}${{cpu cpu{i}}}%${{goto 105}}${{color1}}${{cpubar cpu{i} 4,185}}"
    for i in range(1, int(e["CORES"]) + 1)
)

footer = e["FOOTER"].strip()
if footer:
    bar = "─" * (len(footer) + 2)
    block = (f"${{alignc}}${{color5}}╭{bar}╮\n"
             f"${{alignc}}${{color5}}│ {footer} │\n"
             f"${{alignc}}${{color5}}╰{bar}╯")
else:
    block = ""

wifi, eth = e["WIFI_IFACE"], e["ETH_IFACE"]
wifi_block = (
    f'${{color1}}  Type:   ${{color6}}WiFi\n'
    f'${{color1}}  SSID:   ${{color6}}${{wireless_essid {wifi}}}\n'
    f'${{color1}}  Signal: ${{color6}}${{wireless_link_qual_perc {wifi}}}%  ${{color1}}${{wireless_link_bar 4,160 {wifi}}}\n'
    f'${{color1}}  Up:     ${{color6}}${{upspeed {wifi}}}   ${{color1}}Down: ${{color6}}${{downspeed {wifi}}}\n'
    f'${{color1}}  IP:     ${{color6}}${{addr {wifi}}}')
eth_block = (
    f'${{color3}}  Type:   ${{color6}}Ethernet\n'
    f'${{color3}}  Iface:  ${{color6}}{eth}\n'
    f'${{color3}}  Up:     ${{color6}}${{upspeed {eth}}}   ${{color3}}Down: ${{color6}}${{downspeed {eth}}}\n'
    f'${{color3}}  IP:     ${{color6}}${{addr {eth}}}')
none_block = "${color2}  No network connected"
# Only include what this machine really has: Wi-Fi when connected, else Ethernet when up, else a notice.
if wifi != "none" and eth != "none":
    net = (f'${{if_match "${{wireless_essid {wifi}}}" != "off/any"}}{wifi_block}'
           f'${{else}}${{if_up {eth}}}{eth_block}${{else}}{none_block}${{endif}}${{endif}}')
elif wifi != "none":
    net = f'${{if_match "${{wireless_essid {wifi}}}" != "off/any"}}{wifi_block}${{else}}{none_block}${{endif}}'
elif eth != "none":
    net = f'${{if_up {eth}}}{eth_block}${{else}}{none_block}${{endif}}'
else:
    net = none_block

subs = {
    "@NET_BLOCK@": net, "@CPU_BLOCK@": cpu, "@FOOTER_BLOCK@": block, "@ALIGNMENT@": e["ALIGNMENT"],
    "@BATTERY@": e["BATTERY"],
    "@TEMP_DEV@": e["TEMP_DEV"], "@FACT_SCRIPT@": os.path.join(e["INSTALL_DIR"], "fact.sh"),
}
for k, v in subs.items():
    text = text.replace(k, v)
open(os.path.join(e["INSTALL_DIR"], "dashboard.conkyrc"), "w", encoding="utf-8").write(text)
PY
CONF="$INSTALL_DIR/dashboard.conkyrc"
say "Wrote $CONF"

# ── 4. Autostart + start ────────────────────────────────────────────────────
if [ "$DO_AUTOSTART" = 1 ]; then
  mkdir -p "$(dirname "$AUTOSTART_FILE")"
  cat > "$AUTOSTART_FILE" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Conky Dashboard
Exec=sh -c "sleep 5 && conky -c '$CONF' -d"
X-GNOME-Autostart-enabled=true
DESKTOP
  say "Autostart enabled ($AUTOSTART_FILE)"
fi

if [ "$DO_START" = 1 ]; then
  # Only stop a previous copy of THIS widget, never the user's other conky instances.
  pkill -f "conky -c $CONF" 2>/dev/null || true
  sleep 1
  conky -c "$CONF" -d
  say "Widget started"
fi

cat <<DONE

Done. Edit $CONF to customise, then restart it with:
  pkill -f "conky -c $CONF"; conky -c "$CONF" -d
To remove it later run: $REPO_DIR/uninstall.sh
DONE
