<div align="center">

# 🛡️ Acronis Cyber Protect Agent — AIO Installer

**One script. Every agent task. Zero guesswork.**

Interactive, menu-driven Bash tool to install, uninstall, verify, and
troubleshoot the Acronis Cyber Protect Agent on any Linux host —
built for the Datacomm Cloud Business backup portal
(`cloudbackup.datacomm.co.id`).

[![Version](https://img.shields.io/badge/version-2.2.0-blue.svg)](./installer-acronis.sh)
[![Bash](https://img.shields.io/badge/bash-4%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](#-requirements)
[![License](https://img.shields.io/badge/portal-Datacomm%20BaaS-orange.svg)](http://cloudbackup.datacomm.co.id)

**Quick start →** `sudo bash -c "$(curl -fsSLk https://raw.githubusercontent.com/ipunkpras/acronis-installer/refs/heads/main/installer-acronis.sh)"`

</div>

---

## ✨ Features

| | Feature | What it does |
|---|---|---|
| 🧭 | **Interactive menu** | Pick actions by number or one-letter shortcut — no flags to memorize |
| 🔄 | **Dynamic installer picker** | Fetches live version & installer lists straight from the Datacomm BaaS portal |
| 🔎 | **Smart filter** | Keyword-filter the installer list (e.g. `cyber`, `linux`) before downloading |
| 📊 | **Validated downloads** | Real progress bar, exit-code + size check, atomic `.tmp → move` |
| ⚙️ | **Robust install** | Live output, 30 s heartbeat, real exit code — no fake “completed” |
| 🩺 | **Built-in diagnostics** | CVT (MSP Port Checker) + acropsh health check, downloaded on demand |
| 🔒 | **Password-safe CVT** | Password input is hidden — never echoed to screen or shell history |
| 🧹 | **Safe cleanup** | Removes only this tool’s temp files — never touches unrelated `/tmp` data |

---

## 📦 Menu Overview

```
🛡️   Acronis Cyber Protect Agent Tools
─────────────────────────────────────────
 [1] Install Agent      (i)   → full guided install with token
 [2] Uninstall Agent    (u)   → clean removal + service verify
 [3] Check Services     (s)   → acronis_mms / aakore status
 [4] acropsh Tool       (a)   → agent health-check scripts
 [5] CVT Tool           (c)   → port connectivity checker
 [6] Cleanup Tmp        (l)   → remove tool leftovers in /tmp
 [0] Exit               (q)
```

<details>
<summary>📖 <b>Menu details</b> — what each option does</summary>

### [1] Install Agent `(i)`
1. Fetches the available version list from the portal (live).
2. You pick a version number.
3. *(Optional)* filter the installer list by keyword (`cyber`, `linux`, …).
4. You pick the matching `.bin` installer.
5. Enter your **Registration Token**.
6. Script downloads (validated), then installs with live output + heartbeat.
7. After install it verifies `acronis_mms` is active, then offers to delete the downloaded installer.

> 📄 Install log: `/var/log/acronis-install-<HOSTNAME>-<DATE>.log`
> ⏱️ APT prerequisite phase can take 10–30 min — do **not** Ctrl-C; a heartbeat line prints every 30 s.

### [2] Uninstall Agent `(u)`
Runs Acronis’ own uninstaller, checks its exit code, then verifies
`acronis_mms` is really stopped. Warns if a reboot may still be needed
(kernel module).

### [3] Check Services `(s)`
Green/red status for the two core agent services: `acronis_mms` and `aakore`.

### [4] acropsh Tool `(a)`
Downloads and runs the official Acronis Linux agent health-check
(`main.py` / `linuxAgentChecks.py`) from the Acronis support repository —
analyzes internal agent state. If the SharePoint link 401s, drop the zip
manually at `/tmp/acropsh.zip` and rerun this menu item.

### [5] CVT Tool `(c)`
Downloads and runs the **MSP Port Checker**
(`msp_port_checker_packed.exe` for Linux) to verify every required port to
`cloudbackup.datacomm.co.id` is open. You enter your Acronis Login ID; the
password prompt is **hidden** (no echo — safe for screen-shares and history).

> 📄 Result log: `/tmp/cvt_<HOSTNAME>_<DATE>.log`

### [6] Cleanup Tmp `(l)`
Deletes only files this tool created: `cvt_*.log`, `acropsh_*.log`,
`acropsh_*.zip`, `Linux64.zip` in `/tmp`.

</details>

---

## 🚀 Usage

### One-liner (recommended)

```bash
sudo bash -c "$(curl -fsSLk https://raw.githubusercontent.com/ipunkpras/acronis-installer/refs/heads/main/installer-acronis.sh)"
```

### From a clone

```bash
git clone https://github.com/ipunkpras/acronis-installer.git
cd acronis-installer
sudo bash installer-acronis.sh
```

<details>
<summary>📎 Pin to a specific version (tag)</summary>

```bash
sudo bash -c "$(curl -fsSLk https://raw.githubusercontent.com/ipunkpras/acronis-installer/v2.2.0/installer-acronis.sh)"
```

See [Releases](../../tags) for all tags.
</details>

---

## 📋 Requirements

| Requirement | Detail |
|---|---|
| **OS** | Any modern Linux — Ubuntu, Debian, RHEL, Rocky, AlmaLinux, CentOS, SLES |
| **Privileges** | root (`sudo`) — the script self-checks and exits otherwise |
| **Network** | Outbound internet to the Datacomm portal + Acronis support downloads |
| **Packages** | `wget`; `unzip` is auto-installed if missing; `python3` only for acropsh |
| **Credentials** | Acronis account on the Datacomm BaaS portal (login + registration token) |

---

## 🗺️ Changelog

Format: [Semantic Versioning](https://semver.org) `MAJOR.MINOR.PATCH`

<details>
<summary><b>2.2.0</b> — CVT password hidden + full English messages</summary>

- CVT password prompt no longer echoes to terminal or shell history (`stty -echo`)
- All user-facing messages translated to English
- Script header/version now SemVer (`readonly VERSION="2.2.0"`)
- Git tag `v2.2.0`

</details>

<details>
<summary><b>2.1.x / 2.0.x</b> — reliability overhaul</summary>

- Real installer exit code captured via `wait` (spinner could fake “completed”)
- Download validation: exit code + size vs `Content-Length`, real progress bar, atomic move
- Install: live output + 30 s heartbeat; `DEBIAN_FRONTEND=noninteractive` + `NEEDRESTART_MODE=a`
- Uninstall: exit code check + service-stopped verification + path check first
- acropsh: SharePoint 401 detection → manual `/tmp/acropsh.zip` fallback
- Cleanup: narrow, parenthesized `find` patterns — no longer wipes unrelated `/tmp` zips
- `set -e` removed so the menu survives a failed action
- Post-install: verify `acronis_mms` active
- Dead `progress_bar` code removed

</details>

---

## ⚠️ Notes

- **Token & credentials** are entered at runtime — nothing is stored by the script.
- **Vendor scope**: installers are fetched from the Datacomm BaaS portal — this tool is built for that environment.
- If `acronis_mms` stays inactive after install, check `systemctl status acronis_mms` — the kernel module sometimes needs a reboot.

---

<div align="center">

💡 Built and maintained for **dcloud.co.id** — Datacomm Cloud Business infrastructure.

</div>
