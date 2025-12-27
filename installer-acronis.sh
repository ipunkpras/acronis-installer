#!/bin/bash
# v2.0  Acronis Cyber Protect Agent Installer
# Docker-Compose-like TUI (bash only)

set -euo pipefail

##############  COLOUR & THEME  ################
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'
BLUE='\033[34m'; MAGENTA='\033[35m'; CYAN='\033[36m'
BOLD='\033[1m'; RESET='\033[0m'

##############  UTILS  ########################
log() { echo -e "${2:-}${BOLD}${1}${RESET}"; }
success() { log "✅ ${1}" "$GREEN"; }
error() { log "❌ ${1}" "$RED"; }
warn() { log "⚠️  ${1}" "$YELLOW"; }
info() { log "ℹ️  ${1}" "$BLUE"; }

# Progress bar (inline)  0-100%
progress_bar() {
  local prog=$1
  local width=40
  local fill=$(( prog * width / 100 ))
  local empty=$(( width - fill ))
  printf "\r["
  printf "%${fill}s" | tr ' ' '█'
  printf "%${empty}s" | tr ' ' '░'
  printf "] %3d%%" "$prog"
  [[ $prog -eq 100 ]] && echo
}

spinner() {
  local pid=$1
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${spin:i++%${#spin}:1}  ${2}..."
    sleep 0.1
  done
  printf "\r"
}

##############  PRE-CHECK  ####################
[[ $EUID -ne 0 ]] && { error "Please run as root"; exit 1; }

##############  MENU DRAWER  ##################
draw_box() {
  local -a lines=("$@")
  local edge="╭─$(printf '─%.0s' {1..50})─╮"
  printf "%b\n" "$CYAN$edge$RESET"
  for ln in "${lines[@]}"; do
    printf "│ %-50s │\n" "$ln"
  done
  printf "%b╰─%s─╯%b\n" "$CYAN" "$(printf '─%.0s' {1..50})" "$RESET"
}

##############  MAIN MENU  ####################
show_main_menu() {
  clear
  draw_box \
    "  🛡️  Acronis Cyber Protect Agent Installer  " \
    "  v2.0  |  Datacomm Cloud  |  JKT,ID 2025  "
  echo
  log "Choose action:" "$BOLD"

  # Cetak manual tanpa column -----------
  printf " $GREEN[1] Install Agent     $YELLOW(i)$RESET\n"
  printf " $RED[2] Uninstall         $YELLOW(u)$RESET\n"
  printf " $BLUE[3] Check Services    $YELLOW(s)$RESET\n"
  printf " $MAGENTA[4] acropsh Tool      $YELLOW(a)$RESET\n"
  printf " $CYAN[5] CVT Tool          $YELLOW(c)$RESET\n"
  printf " $YELLOW[6] Cleanup Tmp       $YELLOW(l)$RESET\n"
  printf " $RED[0] Exit              $YELLOW(q)$RESET\n"
  # -------------------------------------

  echo
  read -rp "Press key (shortcut in yellow): " -n 1 key
  echo
  case "${key,,}" in
    i|1) install_agent ;;
    u|2) uninstall_agent ;;
    s|3) check_services ;;
    a|4) run_acropsh ;;
    c|5) run_cvt_tool ;;
    l|6) cleanup ;;
    q|0) log "Bye!" "$GREEN"; exit 0 ;;
    *)   warn "Invalid choice"; sleep 1; show_main_menu ;;
  esac
}

###############  INSTALL AGENT  ################
install_agent() {
  local LOG="/var/log/acronis-install-$(hostname)-$(date +%F-%H-%M).log"
  # helper: catat log + terminal
  log_msg() { echo -e "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

  log_msg "=== Acronis Agent Installation Started ==="

  # 1. Pilih versi
  log_msg "Fetching available versions ..."
  mapfile -t vers < <(wget -qO- https://cloudbackup.datacomm.co.id/download/u/baas/4.0/ |
                        grep -oP 'href="\K[0-9]+\.[0-9]+\.[0-9]+(?=/)' | sort -V)
  [[ ${#vers[@]} -eq 0 ]] && { error "No version found"; return; }

  log_msg "Available versions: ${vers[*]}"
  select v in "${vers[@]}"; do [[ -n $v ]] && break; done
  VERSION=$v
  log_msg "User selected version: $VERSION"

  # 2. Token
  read -rp "Registration Token: " TOKEN
  [[ -z $TOKEN ]] && { error "Token required"; return; }
  log_msg "Token accepted (hidden)"

  # 3. Folder & nama file
  TMP=${TMP_DIR:-$(echo $HOME)/acronis-installer}
  mkdir -p "$TMP"
  BIN=$TMP/Backup_Agent_for_Linux_x86_64.bin
  URL="https://cloudbackup.datacomm.co.id/download/u/baas/4.0/$VERSION/$BIN"

  # 4. Download
  log_msg "Downloading installer to $BIN ..."
  (wget -qO "$BIN" "$URL" 2>&1 | tee -a "$LOG") & spinner $! "Downloading"
  [[ -f $BIN ]] || { error "Download failed"; log_msg "Download failed"; return; }
  chmod +x "$BIN"
  log_msg "Download completed"

  # 5. Install
  log_msg "Running installer ..."
  ./"$BIN" -a --token="$TOKEN" > >(tee -a "$LOG") 2>&1 & spinner $! "Installing"
  local rc=$?
  if [[ $rc -eq 0 ]]; then
    success "Installation completed"
    log_msg "Installation completed successfully"
  else
    error "Installation failed (exit $rc)"
    log_msg "Installation failed (exit $rc)"
    return 1
  fi

  # 6. Hapus installer opsional
  read -rp "Delete installer? [y/N] " del
  if [[ $del =~ ^[Yy]$ ]]; then
    rm -rf "$TMP"
    log_msg "Installer deleted"
  else
    log_msg "Installer kept at $TMP"
  fi

  log_msg "=== Installation Finished ==="
}
##############  UNINSTALL  ####################
uninstall_agent() {
  warn "Starting uninstall..."
  /usr/lib/Acronis/BackupAndRecovery/uninstall/uninstall -a & spinner $! "Uninstalling"
  success "Uninstall finished"
}

##############  SERVICE CHECK  ################
check_services() {
  for svc in aakore acronis_mms; do
    if systemctl is-active --quiet "$svc"; then
      success "$svc is running"
    else
      error "$svc is NOT running"
    fi
  done
  read -n 1 -rp "Press any key to continue..."
}

##############  CVT TOOL  #####################
run_cvt_tool() {
  info "Downloading CVT..."
  wget -qO /tmp/Linux64.zip https://dl.acronis.com/u/support/KB/Linux64.zip
  check_and_install_unzip
  unzip -q /tmp/Linux64.zip -d /tmp/cvt_tool
  chmod +x /tmp/cvt_tool/msp_port_checker_packed.exe
  read -rp "Login: " LOGIN
  /tmp/cvt_tool/msp_port_checker_packed.exe -u="$LOGIN" -h=cloudbackup.datacomm.co.id | tee "/tmp/cvt_$(hostname)_$(date +%F).log"
  success "CVT finished"
}

##############  ACROPSH  ######################
run_acropsh() {
  info "Downloading acropsh..."
  wget -qO /tmp/acropsh.zip 'https://acronis.sharepoint.com/:u:/s/SupportShareExternal/SAT/EZdG6C6SzMZFiSbypQmTi6kB48MuOQxqfG8JoIvxw4dhnQ?e=zyelOA&download=1'
  check_and_install_unzip
  unzip -q /tmp/acropsh.zip -d /tmp/acropsh
  python3 /tmp/acropsh/linux_installation_healthcheck/main.py
  success "acropsh finished"
}

##############  CLEANUP  ######################
cleanup() {
  info "Cleaning temporary files..."
  mapfile -t tmp < <(find /tmp -maxdepth 1 -type f -name 'cvt_*.log' -o -name 'acropsh_*.log' -o -name '*.zip' -o -name 'Linux64.zip')
  for f in "${tmp[@]}"; do rm -f "$f" && printf "."; done
  success "Cleanup done"
}

##############  UNZIP HELPER  #################
check_and_install_unzip() {
  if ! command -v unzip &>/dev/null; then
    warn "unzip not found"
    if command -v apt &>/dev/null; then sudo apt update && sudo apt install -y unzip
    elif command -v yum &>/dev/null; then sudo yum install -y unzip
    elif command -v dnf &>/dev/null; then sudo dnf install -y unzip
    elif command -v zypper &>/dev/null; then sudo zypper install -y unzip
    else error "No supported package manager"; exit 1
    fi
  fi
}

##############  MAIN LOOP  ####################
while true; do
  show_main_menu
done
