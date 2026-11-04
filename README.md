# conky-dashboard

A dark, colourful desktop dashboard for Linux, built with [Conky](https://github.com/brndnmtthws/conky).
It shows, all in one panel:

- date, day-of-year progress bar and five world clocks
- per-core CPU usage and CPU temperature, load average
- RAM, swap and disk usage
- Wi-Fi (name, signal, speed, IP) or Ethernet, whichever you are on
- the top 10 processes
- uptime and battery (hidden automatically on desktops)
- a "Byte of the Day" tech fact that rotates daily and tops itself up from the internet

It is **free and open for anyone**: use it, change it, share it. See [LICENSE](LICENSE) (MIT).

## Requirements

Listed in [requirements.txt](requirements.txt). In short:

| What | Why |
|---|---|
| `conky-all` (1.10 or newer) | draws the widget |
| `python3` | day-of-year bar and the installer (standard library only, no pip packages) |
| `curl`, `iputils-ping` | "Byte of the Day" refill (optional) |
| `fonts-jetbrains-mono` | the font used |

Also needed: an **X11 desktop with a compositor** (Linux Mint, Ubuntu on Xorg, XFCE, KDE on X11, etc.) for the transparent background.
Tested on Linux Mint 22 with conky 1.19.6.

## Install

```bash
git clone https://github.com/Lovepankie/conky-dashboard.git
cd conky-dashboard
./install.sh
```

The installer will:

1. install any missing packages from `requirements.txt` with `apt` (asks for your sudo password)
2. detect your Wi-Fi/Ethernet interface, battery, CPU temperature sensor and number of CPU cores
3. write your personal config to `~/.config/conky-dashboard/dashboard.conkyrc`
4. set the widget to start at login and start it now

Options:

| Option | Meaning |
|---|---|
| `--no-deps` | do not install packages (use this on non-Debian systems after installing the requirements yourself) |
| `--no-autostart` | do not start at login |
| `--no-start` | write the config but do not launch it now |
| `--footer "My Name"` | text in the bottom box (use `--footer ""` for none; default is "© Rincol Tech Solutions") |
| `--alignment bottom_left` | screen corner: `top_left`, `top_right`, `bottom_left`, `bottom_right`, `middle_right`, ... |
| `--cores 4` | how many CPU cores to list (default: your core count, at most 8) |

Re-running `./install.sh` is safe. It keeps the facts the widget already collected.

### Not on Debian, Ubuntu or Mint?

Install the packages from `requirements.txt` with your own package manager
(Fedora: `sudo dnf install conky python3 curl iputils jetbrains-mono-fonts`,
Arch: `sudo pacman -S conky python curl iputils ttf-jetbrains-mono`), then run `./install.sh --no-deps`.

## Customise

Edit `~/.config/conky-dashboard/dashboard.conkyrc`, then restart the widget:

```bash
pkill -f "conky -c $HOME/.config/conky-dashboard/dashboard.conkyrc"
conky -c ~/.config/conky-dashboard/dashboard.conkyrc -d
```

| To change | Edit |
|---|---|
| World clocks | the five `${tztime Region/City %H:%M:%S}` lines (list of zones: `timedatectl list-timezones`) |
| Colours | `color1` to `color6` at the top |
| Size and position | `minimum_width`, `gap_x`, `gap_y`, `alignment` |
| Transparency | `own_window_argb_value` (0 clear, 255 solid) |
| Refresh speed | `update_interval` (seconds) |
| Your own facts | add one line per fact to `~/.config/conky-dashboard/facts.txt` |

If you want changes to survive a re-install, edit the template in `dashboard/dashboard.conkyrc.template` in your clone instead and re-run `./install.sh`.

## Troubleshooting

- **Nothing appears:** run `conky -c ~/.config/conky-dashboard/dashboard.conkyrc` in a terminal and read the error. On Wayland, log in with an Xorg session.
- **Background is a solid block, not transparent:** your desktop has no compositor running. Enable desktop effects/compositing.
- **Temperature is blank or wrong:** run `cat /sys/class/hwmon/hwmon*/name` and put the right sensor name (for example `coretemp` or `k10temp`) in the `${hwmon <name> temp 1}` line.
- **Wrong network shown:** re-run `./install.sh` after connecting, or edit the interface name in the network section.
- **Characters look broken:** install the font (`fonts-jetbrains-mono`) and restart the widget.

## Uninstall

```bash
./uninstall.sh
```

It stops the widget and removes `~/.config/conky-dashboard` and the autostart entry (it asks first). The installed packages are left alone.

## How it works

`install.sh` fills `dashboard/dashboard.conkyrc.template` with what it detected on your machine (interface names, sensor, cores, battery, footer) and writes the result to your config folder. `dashboard/fact.sh` picks the day's fact from `dashboard/facts.txt` by day of the year and, when fewer than 10 facts are left, fetches new tech-related ones from [uselessfacts.jsph.pl](https://uselessfacts.jsph.pl).

## Contributing

Issues and pull requests are welcome. Anyone may fork and change it in any way.

Made by Rincol Tech Solutions.
