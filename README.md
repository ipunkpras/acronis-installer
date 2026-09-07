<div align="center">

# 🛡️ Acronis Cyber Protect Agent — AIO Installer

**One script. Every agent task. Zero guesswork.**

Interactive, menu-driven Bash tool to install, uninstall, verify, and
troubleshoot the Acronis Cyber Protect Agent on any Linux host —
built for the Datacomm Cloud Business backup portal
(`cloudbackup.datacomm.co.id`).

[![Version](https://img.shields.io/badge/version-2.9.7-blue.svg)](./installer-acronis.sh)
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
sudo bash -c "$(curl -fsSLk https://raw.githubusercontent.com/ipunkpras/acronis-installer/v2.9.7/installer-acronis.sh)"
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
<summary><b>2.9.7</b> — symmetric header, status spacing, portal connectivity</summary>

- **Header box centered** — both banner lines now symmetric inside the box (was left-anchored/ragged)
- **Blank line added** between the `Exit` menu item and the agent status block — no more cramped text
- **New portal connectivity line** below the agent status: live TCP probe to `https://cloudbackup.datacomm.co.id` (3s timeout) — shows `Portal: reachable` 🟢 or `unreachable` 🔴 without slowing the menu down

</details>

<details>
<summary><b>2.9.6</b> — intro splash + glitch-free clock</summary>

- **Intro splash**: one-shot "shield arming" animation (growing cyan bar under the banner) when the tool starts — fits the protection theme, gone in under a second
- **Clock fix**: menu no longer clears+redraws every second. It repaints once every **30 seconds** — the 1 Hz full-screen redraw was the source of the terminal glitch/flicker

</details>

<details>
<summary><b>2.9.5</b> — English-only output + aligned menu with descriptions</summary>

- **All user-facing output is now English** (contact-support block translated)
- Menu items **aligned** — every shortcut letter now starts at the same column
- Each menu item gets a **short one-line description** (dim gray, out of the way):

```
[1] Install Agent       (i)  guided multi-portal agent install
[2] Uninstall Agent     (u)  remove agent (two-step confirm)
[3] Check Services      (s)  service status + health verdict
[4] acropsh Tool        (a)  official Acronis health check
[5] CVT Tool            (c)  MSP port checker to portal
[6] Clean Artifacts     (k)  remove leftover tool files
[8] Check Components    (v)  inventory installed components
 ╾───────┤ misc ├───────╼
[7] Help                (h)  usage guide + contacts
[0] Exit               (q)  quit to the shell
```

</details>

<details>
<summary><b>2.9.4</b> — menu polish: updated-date header, live clock, contact info</summary>

- Header shows the tool's **last-updated month/year** + a **live WIB clock** on the main menu (refreshes every second; any keypress stops it instantly)
- **Help** and **Exit** moved into their own separated "misc" column — visually distinct from the operational menu items
- **Help page** now ends with contact information for support:

  ipunk.prasetyo@datacomm.co.id • cloudoperation.engineer@datacomm.co.id

</details>

<details>
<summary><b>2.9.3</b> — cleanup no longer deletes logs/audit trail</summary>

Fix: the post-install cleanup used `rm -rf` on the whole `~/acronis-installer` folder, which also removed the install log `tee` was still writing to (the "No such file or directory" right after "Installer deleted") and wiped `audit.log` on every install. Cleanup now deletes only the `.bin` installer + its `installer-tmp` directory — logs and audit trail stay.

</details>

<details>
<summary><b>2.9.2</b> — manual-mode TUI fix: full-screen wizard</summary>

Fix: in manual mode the .bin was still piped through `tee`, so Acronis' TUI wizard rendered degenerate — a tiny dialog pinned in the top-left corner of a big black terminal. Now manual mode runs the .bin **directly on the controlling terminal** (no pipe), so the wizard fills the screen exactly like a native run: full component checklist, F12 descriptions, Tab/Space navigation.

cli/gui modes unchanged (they still get the tee'd live log + progress messages).

</details>

<details>
<summary><b>2.9.1</b> — third install mode: manual (Acronis' own setup wizard)</summary>

`ACRONIS_MODE=manual` — the guided part (portal picker, version, architecture auto-select, download with progress bar, token in the hidden options-file) stays interactive like GUI mode, but the install step **runs the .bin without `-a`**, so Acronis' own interactive setup wizard appears — the component checklist (Space to tick), F12 component descriptions, Tab navigation. For cases where you want the vendor TUI to drive the install.

Bonus: `ACRONIS_BIN=/path/to/agent.bin` runs an already-downloaded installer wizard directly, skipping the guided flow.

```bash
ACRONIS_MODE=manual sudo -E ./installer-acronis.sh
# or wizard on an existing .bin:
ACRONIS_MODE=manual ACRONIS_BIN=~/acronis-installer/CyberProtect_AgentForLinux_x86_64.bin sudo -E ./installer-acronis.sh
```

</details>

<details>
<summary><b>2.9.0</b> — dual mode: interactive GUI + headless CLI automation</summary>

**CLI mode** — zero prompts, exit codes usable in CI/Ansible/JumpServer automation:

```bash
ACRONIS_MODE=cli ACRONIS_TOKEN=xxx \
  [ACRONIS_PORTAL=1] [ACRONIS_VERSION=latest] [ACRONIS_COMPONENT=] \
  [ACRONIS_DEBUG=1] [ACRONIS_KEEP_BIN=1] \
  sudo -E ./installer-acronis.sh
```

| Env var | Meaning | Default |
|---|---|---|
| `ACRONIS_PORTAL` | `1` = Datacomm preset, or full download-base URL | `1` |
| `ACRONIS_RAIN` | `-C` reg-server override (custom portal only) | .bin built-in |
| `ACRONIS_VERSION` | exact version or `latest` | `latest` |
| `ACRONIS_COMPONENT` | e.g. `AgentForProxmox` | standard agent |
| `ACRONIS_DEBUG` | `1` = installer `-d` verbose | off |
| `ACRONIS_KEEP_BIN` | `1` = keep downloaded .bin | delete |

- Missing token / bad version / bad component / unsupported arch → clean error + `exit 1` (never blocks on a prompt)
- Everything the interactive flow does (multi-portal, arch auto-select, token-in-options-file hidden from `ps`, progress bar) works identically in CLI mode
- GUI menu unchanged — it remains the default when `ACRONIS_MODE` is not set (`gui` = unattended `-a` install; `manual` = Acronis' own wizard, see 2.9.1)

</details>

<details>
<summary><b>2.8.0</b> — multi-portal install</summary>

- **Portal picker** at install start: Datacomm preset, or a **custom portal** where you enter your own download base URL
- **Optional `-C/--rain` registration-server override**: for custom portals you can point registration at any Acronis Cyber Protection service — it is written into the same mode-600 options-file as the token (never visible in `ps`), and shredded after install
- Version scan, architecture auto-select, and the installer download all run against the **chosen portal** instead of the hardcoded Datacomm base
- Portal choice is recorded in the audit log
- Reminder shown when using a non-Datacomm portal: registration tokens do not transfer between portals — get the token from that portal's console

</details>

<details>
<summary><b>2.7.0</b> — loading UX + [8] Check Components</summary>

- **Real progress bars on downloads**: the 1.1 GB installer download now shows a live `% [####----] got/total (elapsed)` bar (polls size against Content-Length) instead of a frozen screen
- **Font-safe spinner**: replaced the braille spinner (which rendered as boxes on PuTTY/Windows terminals) with ASCII `-\|/` plus elapsed seconds
- **Install heartbeat** in human `mm:ss` format
- **New [8] Check Components (v)**: agent version from `installer.version`, registered agents with versions parsed from the Acronis registry XML (e.g. "Agent for Linux (64-bit) 26.7.42848", "Agent for cPanel"), feature directories, and snapapi kernel-module state — a full inventory of what the install actually put on the machine
- HEAD/Content-Length probe now only trusts `200` responses (501 error pages no longer poison the expected size)

</details>

<details>
<summary><b>2.6.0</b> — install hardening: hidden token, components, tmp-dir, debug</summary>

- **Token security**: the registration token is now written to a mode-600 options-file passed via `--options-file` (Acronis' own mechanism to hide sensitive data from `ps`), and the file is shredded after install — the token never appears on the command line or in `ps` output during the long APT phase
- **Component selection**: new step shows the installer's own `--components-list` (e.g. BackupAndRecoveryAgent, AgentForProxmox, MySQLAgentFeature, OracleAgentFeature) — pick a number or press Enter for the standard agent
- **`--tmp-dir`**: installer temp files now go to `~/acronis-installer/installer-tmp/` instead of `/var/tmp`
- **Optional `-d` debug**: prompt before install enables Acronis' verbose log — handy when troubleshooting failed installs

</details>

<details>
<summary><b>2.5.3</b> — acropsh reports born in ~/acronis-installer/</summary>

- `TMPDIR` is now pointed at `~/acronis-installer/` while the health-check runs, so the HTML report is created there natively (no post-run move from `/tmp`); legacy `/tmp` reports are still picked up
- Clean Artifacts info message now reflects reality (cleans both `~/acronis-installer/` and legacy `/tmp`)

</details>

<details>
<summary><b>2.5.2</b> — Help page color fix</summary>

- Fixed the Help page rendering raw `[…m` escape codes: color variables are now defined with ANSI-C quoting (`$'[1m'`) so heredoc output shows real colors instead of literal codes — safe with all existing `echo -e` / `printf %b` call sites

</details>

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
