# CONTEXT.md

Technical status for resuming on any machine.

## What this is
`conky-dashboard`: a packaged, installable version of gEN!u$'s Conky desktop widget (originally `~/.config/conky/genius.conkyrc`). Public, MIT licensed, so anyone can install and modify it.

## Layout
- `install.sh` detects hardware, renders the template, writes `~/.config/conky-dashboard/`, sets autostart, starts it. Installs apt packages listed in `requirements.txt`.
- `uninstall.sh` stops the widget and removes the install dir and autostart entry (asks first).
- `requirements.txt` apt package names (no pip packages).
- `dashboard/dashboard.conkyrc.template` placeholders: `@NET_BLOCK@ @CPU_BLOCK@ @FOOTER_BLOCK@ @TEMP_DEV@ @BATTERY@ @FACT_SCRIPT@ @ALIGNMENT@`.
- `dashboard/fact.sh`, `dashboard/facts.txt` the "Byte of the Day".

## Status (2026-11-04)
- Tested on Linux Mint 22.3 / conky 1.19.6: install renders with no leftover placeholders and conky prints all sections.
- Fixes over the original config: CPU temperature now found by sensor name (was `hwmon 0`, which is the AC adapter on the ProBook, so Temp was blank); core rows follow the real core count; battery block hides itself on machines without a battery; network block only includes Wi-Fi/Ethernet that exist.
- Not yet tested on a real desktop (no Wi-Fi, no battery) or on non-Mint distros.

## Notes
- Do not publish a screenshot taken from the owner's screen: it shows the Wi-Fi name and local IP.
