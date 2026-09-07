<div align="center">

# 🛡️ Acronis Cyber Protect Agent — AIO Installer

**One script. Every agent task. Zero guesswork.**

Interactive, menu-driven Bash tool to install, uninstall, verify, and
troubleshoot the Acronis Cyber Protect Agent on any Linux host —
built for the Datacomm Cloud Business backup portal
(`cloudbackup.datacomm.co.id`).

[![Version](https://img.shields.io/badge/version-2.5.1-blue.svg)](./installer-acronis.sh)
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
 [1] Install Agent      (i)   → guided install: auto OS/arch installer pick
 [2] Uninstall Agent    (u)   → TWO-STEP confirm + service summary first
 [3] Check Services     (s)   → colored status table + health verdict
 [4] acropsh Tool       (a)   → agent health-check scripts
 [5] CVT Tool           (c)   → port connectivity checker (hidden password)
 [6] Clean Artifacts     (k)   → remove tool leftovers in /tmp
 [7] Help                (h)   → usage guide for every function
 [0] Exit               (q)
 ────────────────────────────
 ● Agent footer: live acronis_mms state + INSTALLED AGENT VERSION (e.g. `v26.7.1 build 42848`) shown under the menu
```

<details>
<summary>📖 <b>Menu details</b> — what each option does</summary>

### [1] Install Agent `(i)`
1. Fetches the available version list from the portal (live).
2. You pick a version number.
3. Installer file is **auto-selected by OS architecture** (`uname -m`) — falls back to manual keyword filter on unsupported arch.
4. Enter your **Registration Token**.
6. Script downloads (validated), then installs with live output + heartbeat.
7. After install it verifies `acronis_mms` is active, then offers to delete the downloaded installer.

> 📄 Install log + downloaded installer: `~/acronis-installer/` (per user)
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
analyzes internal agent state. The HTML report is moved into
`~/acronis-installer/` (chmod 644, owned by you). If the SharePoint link
401s, drop the zip manually at `~/acronis-installer/acropsh.zip` and rerun
this menu item.

### [5] CVT Tool `(c)`
Downloads and runs the **MSP Port Checker**
(`msp_port_checker_packed.exe` for Linux) to verify every required port to
`cloudbackup.datacomm.co.id` is open. You enter your Acronis Login ID; the
password prompt is **hidden** (no echo — safe for screen-shares and history).

> 📄 Result log: `~/acronis-installer/cvt_<HOSTNAME>_<DATE>.log`

### [6] Clean Artifacts `(k)`
Deletes only files this tool created: `cvt_*.log`, `acropsh_*.log`,
`acropsh_*.zip`, `acropsh_*.bin`, `Linux64.zip`, and kept
`CyberProtect_AgentFor*.bin` installers — nothing else in `/tmp` is touched.

### [7] Help `(h)`
Built-in usage guide — explains what every menu function does, where logs
and reports are written, and the audit trail location.

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
sudo bash -c "$(curl -fsSLk https://raw.githubusercontent.com/ipunkpras/acronis-installer/v2.5.1/installer-acronis.sh)"
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
<summary><b>2.5.1</b> — all outputs under ~/acronis-installer/</summary>

- Every output now lands in the **real (sudo-invoking) user's** `~/acronis-installer/` directory — visible over SFTP without root: CVT log, acropsh zip + HTML report (moved from `/tmp` and chowned to the user), install log, and the downloaded installer `.bin`
- Audit trail now dual-writes: `~/acronis-installer/audit.log` (user copy) + `/var/log/acronis-tools-<hostname>.log` (root copy)
- Manual acropsh fallback path: `~/acronis-installer/acropsh.zip` (legacy `/tmp/acropsh.zip` still accepted)
- Clean Artifacts cleans both `/tmp` (legacy) and `~/acronis-installer/`

</details>

<details>
<summary><b>2.5.0</b> — Clean Artifacts rename + built-in Help</summary>

- Menu item `Cleanup Tmp` renamed to **Clean Artifacts** (shortcut `k`) — describes the real job: removing leftover artifacts of this tool
- Cleanup now also removes kept `CyberProtect_AgentFor*.bin` installers
- New **Help** menu item (`h`) — in-tool usage guide for every function, log/report locations, and the audit trail

</details>

<details>
<summary><b>2.4.3</b> — installer auto-selected by OS architecture</summary>

- Install flow now **auto-selects the installer** matching the machine's OS and CPU architecture (`uname -m`: x86_64 / x86 / arm64) — no more typing or browsing the 38-file list
- If multiple matches: short numbered pick; if no match (unsupported arch): manual keyword filter fallback (previous behavior)

</details>

<details>
<summary><b>2.4.2</b> — menu footer shows installed agent version</summary>

- Menu footer now displays the **installed Acronis agent version** (e.g. `v26.7.1 build 42848`) alongside the service state — read from `/opt/acronis/var/aakore/installer.version`, with package-manager and `aakore` CLI fallbacks
- Footer states: `running` / `stopped` / `not installed`

</details>

<details>
<summary><b>2.4.1</b> — kmod inactive explainer</summary>

- When `acronis_kmod_service` shows `inactive` in the service table (both in uninstall preview and Check Services), an informational message explains it is a **one-shot DKMS helper** that builds the `snapapi` kernel module then exits — inactive after a successful build is normal; verify the module with `lsmod | grep snapapi`

</details>

<details>
<summary><b>2.4.0</b> — UX overhaul + audit trail + safe uninstall</summary>

- **Audit trail**: every action (start, result, exit code) is appended to `/var/log/acronis-tools-<hostname>.log` — one persistent, reviewable history per host
- **Uninstall is now two-step**: a service summary table is shown **before** anything is removed, then `y/N` confirmation, then typing `UNINSTALL` in full — no accidental removals
- **Pre-uninstall service summary**: colored table of `aakore`, `acronis_mms`, `acronis_schedule`, `acronis_kmod_service` states
- **Numbered step labels** (`Step 1 … Step 6`) guide the install flow
- **Menu footer**: live `acronis_mms` status dot + version shown under the menu
- `Check Services` now renders the same colored table + overall health verdict

</details>

<details>
<summary><b>2.3.1</b> — acropsh report fetchable via SFTP</summary>

- acropsh HTML report (`/tmp/*-service_summary.html`) is now chmod 644 after each run — previously created root-only (600) by Python tempfile, so SFTP users without root could not read it
- The report path is printed after the run for easy retrieval

</details>

<details>
<summary><b>2.3.0</b> — acropsh 401 fixed</summary>

- acropsh download no longer fails with HTTP 401: two-step SharePoint fetch (visit the share page to get the session cookie, then download with it)
- Manual `/tmp/acropsh.zip` fallback still available as plan B

</details>

<details>
<summary><b>2.2.1</b> — CVT password really hidden</summary>

- Root cause found: the packed CVT binary re-enables tty echo on its own password prompt, so `stty -echo` was not enough
- Password is now read hidden by bash itself (`read -rs`) and piped to CVT stdin — nothing is ever echoed to screen or history
- `unset PASSWORD` after use

</details>

<details>
<summary><b>2.2.0</b> — English messages + SemVer</summary>

- All user-facing messages translated to English
- Script header/version now SemVer (`readonly VERSION`)
- CVT: first attempt to hide password via `stty -echo` (superseded by 2.2.1)
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
