#!/bin/bash
# Acronis Cyber Protect Agent Installer   •   dcloud.co.id
readonly VERSION="2.4.2"   # Semantic Versioning: MAJOR.MINOR.PATCH
# 2.4.2 — menu footer shows the RUNNING Acronis agent version
#   (installer.version / package / aakore CLI fallbacks) instead of tool info only
# 2.4.1 — kmod note: informational message when acronis_kmod_service is
#   inactive (oneshot DKMS builder — normal after module is built)
# 2.4.0 — UX + audit layer:
#  - audit(): every action (start/result/exit code) appended to
#    /var/log/acronis-tools-<hostname>.log — one persistent audit trail
#  - uninstall: TWO-STEP confirm (y/N then type UNINSTALL) + service summary
#    table shown BEFORE anything is removed
#  - numbered step() progress labels in install flow
#  - menu: aligned status line showing acronis_mms live state
#  - svc_table(): colored service summary reused by check + uninstall
# 2.3.1 — changes (on top of 2.0.0 fixes):
#  - acropsh: HTML report chmod 644 after run (tempfile creates it root:600,
#    unreadable via SFTP without root) + path printed after run
# 2.3.0 — changes (on top of 2.0.0 fixes):
#  - acropsh: fix 401 download — two-step SharePoint fetch (visit page for
#    session cookie, then download with it). Manual /tmp/acropsh.zip fallback kept.
# 2.2.1 — changes (on top of 2.0.0 fixes):
#  - CVT: password now read hidden by bash (read -s) and piped to CVT
#    stdin — packed binary re-enables echo itself, stty -echo was not enough
# 2.2.0 — changes (on top of 2.0.0 fixes):
#  - CVT: password prompt no longer echoes to terminal/history
#  - all user-facing messages now English
#  - exit code ASLI di-capture via wait (spinner v2.0 selalu return 0 →
#    fake "Installation completed" even when installer failed)
#  - download divalidasi: exit code + ukuran file vs Content-Length,
#    progress bar nyata (bukan spinner diam), atomic (.tmp → move)
#  - install: live output + heartbeat every 30s (no more "dark stuck" feel),
#    DEBIAN_FRONTEND=noninteractive + NEEDRESTART_MODE=a (skip prompt
#    needrestart yang bikin fase APT kelihatan menggantung)
#  - uninstall: cek exit code + verifikasi service mati + cek path dulu
#  - acropsh: link SharePoint bisa 401 → deteksi + fallback /tmp/acropsh.zip
#  - cleanup: find dengan kurung (precedence) + pattern sempit,
#    TIDAK lagi hapus semua *.zip di /tmp
#  - check_and_install_unzip: tanpa sudo (script sudah root), apt-get -qq
#  - set -e removed: menu survives a failed action
#  - post-install: verify acronis_mms active
#  - dead code progress_bar dihapus

set -uo pipefail

##############  COLOUR & THEME  ################
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'
BLUE='\033[34m'; MAGENTA='\033[35m'; CYAN='\033[36m'
BOLD='\033[1m'; RESET='\033[0m'

DL_BASE="https://cloudbackup.datacomm.co.id/download/u/baas/4.0"

##############  UTILS  ########################
log() { echo -e "${2:-}${BOLD}${1}${RESET}"; }
success() { log "✅ ${1}" "$GREEN"; }
error() { log "❌ ${1}" "$RED"; }
warn()  { log "⚠️  ${1}" "$YELLOW"; }
info()  { log "ℹ️  ${1}" "$BLUE"; }

# spinner dengan line-clear (\033[K) — v2.0 menimpa baris tanpa clear
spinner() {
  local pid=$1 spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r\033[K%s %s..." "${spin:i++%${#spin}:1}" "$2"
    sleep 0.15
  done
  printf "\r\033[K"
}

# jalankan cmd background + spinner, RETURN exit code asli via wait
run_bg() {
  local label=$1; shift
  "$@" & local pid=$!
  spinner "$pid" "$label"
  wait "$pid"
}

pause() {
  echo
  read -n1 -rp "$(echo -e "${YELLOW}Press any key to return to menu...${RESET}")"
  echo
}

# 2.4.0: persistent audit trail — every action + result lands in one log
AUDIT_LOG="/var/log/acronis-tools-$(hostname).log"
audit() { echo "[$(date '+%F %T')] $*" >> "$AUDIT_LOG"; }

# 2.4.0: numbered step label for guided flows
step() { echo; echo -e "${BOLD}${CYAN}━━ Step $1: ${2}${RESET}"; }

# 2.4.0: colored service summary table (reused by check + uninstall)
svc_table() {
  local svc desc colored
  printf "%b\n" "${BOLD}┌───────────────────────┬───────────────────────────────┬──────────┐${RESET}"
  printf "%b\n" "${BOLD}│ Service               │ Description                   │ State    │${RESET}"
  printf "%b\n" "${BOLD}├───────────────────────┼───────────────────────────────┼──────────┤${RESET}"
  while [[ $# -ge 2 ]]; do
    svc=$1; desc=$2; shift 2
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
      colored="${GREEN}active  ${RESET}"
    else
      colored="${RED}inactive${RESET}"
    fi
    printf "%b %-21s %b %-28s %b %b %b\n" "${BOLD}│${RESET}" "$svc" "${BOLD}│${RESET}" "$desc" "${BOLD}│${RESET}" "$colored" "${BOLD}│${RESET}"
  done
  printf "%b\n" "${BOLD}└───────────────────────┴───────────────────────────────┴──────────┘${RESET}"
}

##############  PRE-CHECK  ####################
[[ $EUID -ne 0 ]] && { echo "Please run as root"; exit 1; }

##############  MENU DRAWER  ##################
draw_box() {
  local -a lines=("$@")
  local width=44

  display_width() {
    local clean
    clean=$(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')
    local n
    n=$(echo -n "$clean" | wc -m)
    [[ "$clean" == *"🛡️"* ]] && n=$((n - 1))
    echo "$n"
  }

  local border
  border=$(printf '─%.0s' $(seq 1 "$width"))
  printf "%b╭─%s─╮%b\n" "$CYAN" "$border" "$RESET"
  local ln pad
  for ln in "${lines[@]}"; do
    pad=$((width - $(display_width "$ln")))
    [[ $pad -lt 0 ]] && pad=0
    printf "%b│%b %s%*s%b │%b\n" "$CYAN" "$RESET" "$ln" "$pad" "" "$CYAN" "$RESET"
  done
  printf "%b╰─%s─╯%b\n" "$CYAN" "$border" "$RESET"
}

# 2.4.2: menu footer — installed Acronis agent version + service state
agent_version() {
  local v=""
  # a) official version file (aakore)
  if [[ -r /opt/acronis/var/aakore/installer.version ]]; then
    local maj min pat build
    maj=$(grep -oP 'MAJOR_VERSION=\K[0-9]+' /opt/acronis/var/aakore/installer.version 2>/dev/null)
    min=$(grep -oP 'MINOR_VERSION=\K[0-9]+' /opt/acronis/var/aakore/installer.version 2>/dev/null)
    pat=$(grep -oP 'PATCH_VERSION=\K[0-9]+' /opt/acronis/var/aakore/installer.version 2>/dev/null)
    build=$(grep -oP 'BUILD_NUMBER=\K[0-9]+' /opt/acronis/var/aakore/installer.version 2>/dev/null)
    [[ -n $maj ]] && v="$maj.$min.$pat${build:+ build $build}"
  fi
  # b) fallback: dpkg/rpm package version
  if [[ -z $v ]]; then
    v=$(dpkg-query -W -f'${Version}' 'acronis-mms' 2>/dev/null) || true
    [[ -z $v ]] && v=$(rpm -q --qf '%{VERSION}' acronis-mms 2>/dev/null) || true
  fi
  # c) fallback: aakore CLI
  if [[ -z $v ]]; then
    v=$(/opt/acronis/aakore version 2>/dev/null | grep -oP 'version \K[0-9.+]+' ) || true
  fi
  echo "$v"
}

agent_status_line() {
  local ver; ver=$(agent_version)
  [[ -n $ver ]] && ver=" (v$ver)"
  if systemctl is-active --quiet acronis_mms 2>/dev/null; then
    echo -e " ${GREEN}●${RESET} Agent: ${GREEN}running${RESET}   ${BOLD}acronis_mms active${RESET}$ver   ${BOLD}tool v${VERSION}${RESET}"
  elif [[ -n $ver ]]; then
    echo -e " ${RED}○${RESET} Agent: ${RED}stopped${RESET}   ${BOLD}acronis_mms inactive${RESET}$ver   ${BOLD}tool v${VERSION}${RESET}"
  else
    echo -e " ${RED}○${RESET} Agent: ${RED}not installed${RESET}   ${BOLD}tool v${VERSION}${RESET}"
  fi
}

##############  MAIN MENU  ####################
show_main_menu() {
  clear
  draw_box \
    '🛡️   Acronis Cyber Protect Agent Tools' \
    "$VERSION • https://dcloud.co.id   • JKT,ID 2025"
  echo
  log "Choose action:" "$BOLD"

  printf " $GREEN[1] Install Agent      $YELLOW(i)$RESET\n"
  printf " $RED[2] Uninstall Agent    $YELLOW(u)$RESET\n"
  printf " $BLUE[3] Check Services     $YELLOW(s)$RESET\n"
  printf " $MAGENTA[4] acropsh Tool       $YELLOW(a)$RESET\n"
  printf " $CYAN[5] CVT Tool           $YELLOW(c)$RESET\n"
  printf " $YELLOW[6] Cleanup Tmp        $YELLOW(l)$RESET\n"
  printf " $RED[0] Exit               $YELLOW(q)$RESET\n"

  echo
  agent_status_line
  echo
  read -rp "Press key (shortcut in yellow): " -n1 key
  echo
  case "${key,,}" in
    i|1) audit "MENU: install_agent start";  install_agent  && audit "ACTION install_agent: OK"   || { audit "ACTION install_agent: FAILED"; warn "Install finished with error"; };;
    u|2) audit "MENU: uninstall_agent start"; uninstall_agent && audit "ACTION uninstall_agent: OK" || { audit "ACTION uninstall_agent: FAILED"; warn "Uninstall finished with error"; };;
    s|3) audit "MENU: check_services"; check_services;;
    a|4) audit "MENU: acropsh start"; run_acropsh && audit "ACTION acropsh: OK" || { audit "ACTION acropsh: FAILED"; warn "acropsh finished with error"; };;
    c|5) audit "MENU: cvt start"; run_cvt_tool && audit "ACTION cvt: OK" || { audit "ACTION cvt: FAILED"; warn "CVT finished with error"; };;
    l|6) audit "MENU: cleanup"; cleanup;;
    q|0) audit "MENU: exit"; log "Bye!" "$GREEN"; exit 0;;
    *)   warn "Invalid choice"; sleep 1;;
  esac
}

##############  FETCH HELPER  ##################
# wget dengan fallback --no-check-certificate (self-signed di beberapa tenant)
fetch_page() {
  local url=$1 out
  out=$(wget -qO- "$url" 2>/dev/null) && { printf '%s' "$out"; return 0; }
  out=$(wget -qO- --no-check-certificate "$url" 2>/dev/null) && { printf '%s' "$out"; return 0; }
  return 1
}

##############  DOWNLOAD HELPER  ##############
# validated download: rc + size vs Content-Length, progress nyata, atomic
download() {
  local url=$1 dest=$2 expected got rc
  expected=$(curl -sIL --max-time 20 "$url" 2>/dev/null \
             | awk 'tolower($1) ~ /^content-length:/ {v=$2} END {print int(v)}' | tr -d '\r')
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --connect-timeout 15 -o "$dest.tmp" "$url"
    rc=$?
  else
    wget -O "$dest.tmp" "$url"
    rc=$?
  fi
  got=$(stat -c%s "$dest.tmp" 2>/dev/null || echo 0)
  if [[ $rc -ne 0 || ( ${expected:-0} -gt 0 && $got -ne $expected ) ]]; then
    rm -f "$dest.tmp"
    return 1
  fi
  mv -f "$dest.tmp" "$dest"
  chmod +x "$dest"
  return 0
}

###############  INSTALL AGENT  ################
install_agent() {
  local LOG="/var/log/acronis-install-$(hostname)-$(date +%F-%H-%M).log"
  log_msg() { echo -e "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

  log_msg "=== Acronis Agent Installation Started ==="

  # 1. choose version
  step 1 "Fetch available versions from the portal"
  log_msg "Fetching available versions ..."
  local page
  page=$(fetch_page "$DL_BASE/") || { error "Cannot reach $DL_BASE"; log_msg "ERROR: cannot reach $DL_BASE"; pause; return 1; }
  mapfile -t vers < <(grep -oP 'href="\K[0-9]+\.[0-9]+\.[0-9]+(?=/)' <<<"$page" | sort -uV)
  [[ ${#vers[@]} -eq 0 ]] && { error "No version found"; pause; return 1; }

  echo "Available versions:"
  local i num
  for i in "${!vers[@]}"; do echo "  $((i+1)). ${vers[$i]}"; done

  while true; do
    read -rp "Select version number: " num
    [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#vers[@]} )) && break
    warn "Enter number between 1 and ${#vers[@]}"
  done
  local DL_VERSION=${vers[$((num-1))]}
  log_msg "User selected version: $DL_VERSION"

  # 2. scan installer list
  step 2 "Scan installer files"
  local BASE_URL="$DL_BASE/$DL_VERSION"
  log_msg "Scanning installers at $BASE_URL ..."
  page=$(fetch_page "$BASE_URL/") || { error "Cannot reach $BASE_URL"; log_msg "ERROR: cannot reach $BASE_URL"; pause; return 1; }
  mapfile -t installers < <(grep -oP 'href="\K[^\"]+\.(bin|exe|dmg|spk)(?=\")' <<<"$page" | sort -uV)
  [[ ${#installers[@]} -eq 0 ]] && { error "No installer found"; pause; return 1; }

  # 3. filter
  echo ""
  echo "Available installers (${#installers[@]} total):"
  for i in "${!installers[@]}"; do echo "  $((i+1)). ${installers[$i]}"; done

  echo ""
  local keyword
  read -rp "Enter filter keyword (or press Enter to show all): " keyword
  local filtered=("${installers[@]}")
  if [[ -n "${keyword:-}" ]]; then
    mapfile -t filtered < <(printf '%s\n' "${installers[@]}" | grep -i "$keyword" || true)
    if [[ ${#filtered[@]} -eq 0 ]]; then
      warn "No installer matches keyword '$keyword', showing all installers"
      filtered=("${installers[@]}")
    else
      log_msg "Filtered by keyword '$keyword': ${#filtered[@]} result(s)"
    fi
  fi

  echo ""
  echo "Filtered installers (${#filtered[@]} found):"
  for i in "${!filtered[@]}"; do echo "  $((i+1)). ${filtered[$i]}"; done

  # 4. choose installer
  step 3 "Select installer file"
  [[ ${#filtered[@]} -eq 0 ]] && { error "No installer available to select"; pause; return 1; }
  while true; do
    read -rp "Select installer number: " num
    [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#filtered[@]} )) && break
    warn "Enter number between 1 and ${#filtered[@]}"
  done
  local INSTALLER=${filtered[$((num-1))]}
  log_msg "User selected installer: $INSTALLER"

  # 5. token
  step 4 "Registration token"
  local TOKEN
  read -rp "Registration Token: " TOKEN
  [[ -z $TOKEN ]] && { error "Token required"; pause; return 1; }
  log_msg "Token accepted (hidden)"

  # 6. path
  local REAL_USER=${SUDO_USER:-$USER}
  local REAL_HOME TMP BIN URL
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
  TMP=${TMP_DIR:-$REAL_HOME/acronis-installer}
  mkdir -p "$TMP"
  BIN=$TMP/$INSTALLER
  URL="$BASE_URL/$INSTALLER"

  # 7. download (validated)
  log_msg "Downloading installer to $BIN ..."
  if download "$URL" "$BIN"; then
    log_msg "Download completed ($(numfmt --to=iec "$(stat -c%s "$BIN")" 2>/dev/null || stat -c%s "$BIN") bytes)"
  else
    error "Download failed (network / 404 / size mismatch)"
    log_msg "Download failed"
    pause
    return 1
  fi

  # 8. install — live output + heartbeat, rc ASLI
  step 5 "Install (live output, APT phase may take 10-30 min)"
  log_msg "Running installer ..."
  export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a
  info "Installer output shown live. APT prereq phase may take 10-30 min — do not Ctrl-C."
  "$BIN" -a --token="$TOKEN" > >(tee -a "$LOG") 2>&1 &
  local pid=$! t0=$SECONDS
  while kill -0 "$pid" 2>/dev/null; do
    sleep 30
    kill -0 "$pid" 2>/dev/null && info "installer still running ... $((SECONDS-t0))s"
  done
  wait "$pid"
  local rc=$?

  if [[ $rc -eq 0 ]]; then
    success "Installation completed (exit 0)"
    log_msg "Installation completed successfully"
    sleep 5
    if systemctl is-active --quiet acronis_mms 2>/dev/null; then
      success "service acronis_mms active"
      log_msg "acronis_mms active"
    else
      warn "acronis_mms not active yet — check systemctl status acronis_mms (kernel module may need reboot)"
      log_msg "WARN: acronis_mms not active after install"
    fi
  else
    error "Installation failed (exit $rc)"
    log_msg "Installation failed (exit $rc)"
    pause
    return "$rc"
  fi

  # 9. optional delete
  step 6 "Cleanup installer file"
  local del
  read -rp "Delete installer? [y/N] " del
  if [[ $del =~ ^[Yy]$ ]]; then
    rm -rf "$TMP"
    log_msg "Installer deleted"
  else
    log_msg "Installer kept at $TMP"
  fi

  log_msg "=== Installation Finished ==="
  pause
}

##############  UNINSTALL  ####################
uninstall_agent() {
  local u=/usr/lib/Acronis/BackupAndRecovery/uninstall/uninstall
  if [[ ! -x $u ]]; then
    error "Uninstaller not found: $u"
    warn "Is the agent installed? Check: dpkg -l | grep -i acronis"
    pause
    return 1
  fi

  # --- 2.4.0: pre-uninstall service summary + TWO-STEP confirmation ---
  echo
  warn "This will remove the Acronis Cyber Protect Agent from this machine."
  echo
  svc_table \
    aakore "Acronis Agent Core" \
    acronis_mms "Managed Machine Service" \
    acronis_schedule "Schedule Service" \
    acronis_kmod_service "Kernel Module Service"
  # kmod oneshot service: inactive after build = normal
  if ! systemctl is-active --quiet acronis_kmod_service 2>/dev/null; then
    info "acronis_kmod_service inactive is NORMAL — it is a one-shot DKMS helper"
    info "that builds the snapapi kernel module (e.g. after kernel update),"
    info "then exits. The loaded module stays working — check: lsmod | grep snapapi"
  fi
  echo
  local confirmed
  read -rp "Type y to continue with uninstall [y/N]: " confirmed
  [[ ! $confirmed =~ ^[Yy]$ ]] && { info "Uninstall cancelled."; audit "uninstall: cancelled at step 1"; return 0; }

  echo
  warn "SECOND CONFIRMATION — this action is hard to reverse."
  read -rp "Type UNINSTALL in uppercase to proceed: " confirmed
  [[ $confirmed != "UNINSTALL" ]] && { info "Uninstall cancelled."; audit "uninstall: cancelled at step 2"; return 0; }

  audit "uninstall: confirmed (both steps), starting"
  warn "Starting uninstall..."
  run_bg "Uninstalling" "$u" -a
  local rc=$?
  audit "uninstall: uninstaller exit code $rc"
  if [[ $rc -eq 0 ]]; then
    success "Uninstall finished (exit 0)"
  else
    error "Uninstall failed (exit $rc)"
  fi
  sleep 2
  systemctl is-active --quiet acronis_mms 2>/dev/null \
    && warn "acronis_mms still active — reboot may be required" \
    || success "acronis_mms no longer active"
  pause
  return "$rc"
}

##############  SERVICE CHECK  ################
check_services() {
  svc_table \
    aakore "Acronis Agent Core" \
    acronis_mms "Managed Machine Service" \
    acronis_schedule "Schedule Service" \
    acronis_kmod_service "Kernel Module Service"
  # kmod oneshot service: inactive after build = normal
  if ! systemctl is-active --quiet acronis_kmod_service 2>/dev/null; then
    info "acronis_kmod_service inactive is NORMAL — it is a one-shot DKMS helper"
    info "that builds the snapapi kernel module (e.g. after kernel update),"
    info "then exits. The loaded module stays working — check: lsmod | grep snapapi"
  fi
  if systemctl is-active --quiet acronis_mms 2>/dev/null; then
    success "Agent is healthy"
  else
    error "acronis_mms not running — agent NOT healthy"
  fi
  pause
}

##############  CVT TOOL  #####################
run_cvt_tool() {
  local output_file="/tmp/cvt_$(hostname)_$(date +%F).log"

  info "Downloading CVT..."
  if ! download "https://dl.acronis.com/u/support/KB/Linux64.zip" /tmp/Linux64.zip; then
    error "CVT download failed (network?)"
    pause
    return 1
  fi
  check_and_install_unzip || { pause; return 1; }
  rm -rf /tmp/cvt_tool
  unzip -q -o /tmp/Linux64.zip -d /tmp/cvt_tool || { error "unzip failed"; pause; return 1; }
  chmod +x /tmp/cvt_tool/msp_port_checker_packed.exe

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  info "Output file will be saved to: $output_file"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local LOGIN PASSWORD
  read -rp "Login: " LOGIN
  # 2.2.1: the packed CVT binary re-enables tty echo on its own prompt,
  # so stty -echo cannot hide it. Instead bash reads the password hidden
  # (read -s: no echo, nothing in history) and pipes it to CVT stdin.
  read -rs -p "Password: " PASSWORD
  echo
  printf '%s\n' "$PASSWORD" | timeout 300 /tmp/cvt_tool/msp_port_checker_packed.exe -u="$LOGIN" -h=cloudbackup.datacomm.co.id 2>&1 | tee "$output_file"
  local rc=${PIPESTATUS[1]}
  unset PASSWORD

  echo ""
  if [[ $rc -eq 0 ]]; then
    success "CVT finished"
  else
    error "CVT failed (exit $rc)"
  fi
  info "Log file saved at: $output_file"
  echo ""
  pause
  return "$rc"
}

##############  ACROPSH  ######################
run_acropsh() {
  # Official source (KB 67276). SharePoint rejects anonymous direct downloads
  # with 401 unless the share page was visited first (session cookie).
  # 2.3.0: two-step download — browse page first to collect the cookie, then fetch.
  local acropsh_url='https://acronis.sharepoint.com/:u:/s/SupportShareExternal/SAT/EZdG6C6SzMZFiSbypQmTi6kB48MuOQxqfG8JoIvxw4dhnQ?e=zyelOA'
  local share_ua='Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0'
  local cookiejar; cookiejar=$(mktemp)
  local zip_file="/tmp/acropsh_$(date +%s).zip"
  local extract_dir="/tmp/acropsh_x_$(date +%s)"

  info "Downloading acropsh (2-step SharePoint auth)..."
  # step 1: visit the share page to obtain the session cookie
  curl -sL --max-time 60 -A "$share_ua" -c "$cookiejar" -o /dev/null \
        "$acropsh_url" 2>/dev/null
  # step 2: actual download, reusing the cookie
  local code
  code=$(curl -sL --max-time 180 -A "$share_ua" -b "$cookiejar" \
        -o "$zip_file" -w '%{http_code}' "$acropsh_url&download=1" 2>/dev/null || echo 000)
  rm -f "$cookiejar"

  if [[ $code != 200 ]]; then
    rm -f "$zip_file"
    if [[ -f /tmp/acropsh.zip ]]; then
      zip_file=/tmp/acropsh.zip
      info "Using /tmp/acropsh.zip (manual download)"
    else
      error "Download failed (HTTP $code — link requires auth / expired)"
      info "Workaround: download manually via browser, save as /tmp/acropsh.zip, then rerun this menu item."
      pause
      return 1
    fi
  fi

  if ! file "$zip_file" | grep -q "Zip archive"; then
    error "Downloaded file is not a valid ZIP"
    rm -f "$zip_file"
    pause
    return 1
  fi

  check_and_install_unzip || { pause; return 1; }

  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"
  if ! unzip -q "$zip_file" -d "$extract_dir" 2>&1; then
    error "Failed to extract ZIP"
    rm -rf "$zip_file" "$extract_dir"
    pause
    return 1
  fi

  local target_dir
  target_dir=$(find "$extract_dir" -name "linux_installation_healthcheck" -type d 2>/dev/null | head -n1)

  if [[ -z $target_dir ]]; then
    if [[ -f "$extract_dir/linuxAgentChecks.py" ]]; then
      target_dir="$extract_dir"
    else
      error "Unexpected folder structure. Extract contents:"
      find "$extract_dir" -type f | head -10
      rm -rf "$extract_dir"
      pause
      return 1
    fi
  fi

  info "Running acropsh from: $target_dir"
  cd "$target_dir" || { error "Cannot cd to $target_dir"; pause; return 1; }

  local rc=1
  if [[ -f "main.py" ]]; then
    python3 main.py; rc=$?
  elif [[ -f "linuxAgentChecks.py" ]]; then
    python3 linuxAgentChecks.py; rc=$?
  else
    error "No main.py or linuxAgentChecks.py found"
    ls -la
  fi
  cd - >/dev/null

  # 2.3.1: acropsh writes its HTML report via tempfile.NamedTemporaryFile
  # (mkstemp) → mode 600 owned by root, unreadable over SFTP by normal users.
  # Make the newest service_summary report world-readable so it can be
  # fetched without root.
  local report
  report=$(ls -t /tmp/*-service_summary.html 2>/dev/null | head -n1)
  if [[ -n $report ]]; then
    chmod 644 "$report"
    info "Report (readable via SFTP): $report"
  fi

  if [[ $rc -eq 0 ]]; then
    success "acropsh finished"
  else
    error "acropsh failed with exit code $rc"
  fi

  rm -rf "$zip_file" "$extract_dir"
  pause
  return "$rc"
}

##############  CLEANUP  ######################
cleanup() {
  info "Cleaning temporary files..."
  # ponytail: pattern sempit + kurung (precedence find) — jangan sentuh zip lain
  find /tmp -maxdepth 1 -type f \
       \( -name 'cvt_*.log' -o -name 'acropsh_*.log' -o -name 'acropsh_*.zip' \
          -o -name 'Linux64.zip' \) -print -delete
  success "Cleanup done"
  pause
}

##############  UNZIP HELPER  #################
check_and_install_unzip() {
  command -v unzip >/dev/null 2>&1 && return 0
  warn "unzip not found — installing..."
  if   command -v apt-get >/dev/null 2>&1; then apt-get update -qq && apt-get install -y unzip
  elif command -v dnf     >/dev/null 2>&1; then dnf     install -y unzip
  elif command -v yum     >/dev/null 2>&1; then yum     install -y unzip
  elif command -v zypper  >/dev/null 2>&1; then zypper  -n install unzip
  else error "No supported package manager"; return 1
  fi
}

##############  MAIN LOOP  ####################
while true; do
  show_main_menu
done
