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

# Fungsi pause - tunggu user tekan key sebelum kembali ke menu
pause() {
  echo
  read -n 1 -rp "$(echo -e "${YELLOW}Press any key to return to menu...${RESET}")" 
  echo
}

##############  PRE-CHECK  ####################
[[ $EUID -ne 0 ]] && { error "Please run as root"; exit 1; }

##############  MENU DRAWER  ##################
draw_box() {
  local -a lines=("$@")
  local width=44 
  
  display_width() {
    local str="$1"
   
    local clean=$(echo -e "$str" | sed 's/\x1b\[[0-9;]*m//g')
    local char_count=$(echo -n "$clean" | wc -m)

    if [[ "$clean" == *"🛡️"* ]]; then
      char_count=$((char_count - 1))
    fi
    echo "$char_count"
  }
  
  local border=$(printf '─%.0s' $(seq 1 $width))
  printf "%b╭─%s─╮%b\n" "$CYAN" "$border" "$RESET"
  
  for ln in "${lines[@]}"; do
    local content_width=$(display_width "$ln")
    local pad=$((width - content_width))
    [[ $pad -lt 0 ]] && pad=0
    
    printf "%b│%b %s%*s%b │%b\n" "$CYAN" "$RESET" "$ln" "$pad" "" "$CYAN" "$RESET"
  done
  
  printf "%b╰─%s─╯%b\n" "$CYAN" "$border" "$RESET"
}

##############  MAIN MENU  ####################
show_main_menu() {
  clear
  draw_box \
    '🛡️   Acronis Cyber Protect Agent Tools' \
    'v2.0 • https://dcloud.co.id   • JKT,ID 2025'
  echo
  log "Choose action:" "$BOLD"

  printf " $GREEN[1] Install Agent     $YELLOW(i)$RESET\n"
  printf " $RED[2] Uninstall Agent   $YELLOW(u)$RESET\n"
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
    *)   warn "Invalid choice"; sleep 1 ;;
  esac
}
###############  INSTALL AGENT  ################
install_agent() {
  local LOG="/var/log/acronis-install-$(hostname)-$(date +%F-%H-%M).log"
  log_msg() { echo -e "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

  log_msg "=== Acronis Agent Installation Started ==="

  # 1. Pilih versi
  log_msg "Fetching available versions ..."
  mapfile -t vers < <(wget -qO- https://cloudbackup.datacomm.co.id/download/u/baas/4.0/   |
                        grep -oP 'href="\K[0-9]+\.[0-9]+\.[0-9]+(?=/)' | sort -V)
  [[ ${#vers[@]} -eq 0 ]] && { error "No version found"; pause; return; }

  echo "Available versions:"
  for i in "${!vers[@]}"; do
      echo "  $((i+1)). ${vers[$i]}"
  done

  while true; do
      read -rp "Select version number: " num
      [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#vers[@]} )) && break
      warn "Enter number between 1 and ${#vers[@]}"
  done
  VERSION="${vers[$((num-1))]}"
  log_msg "User selected version: $VERSION"

  # 2. Scan daftar installer di folder versi
  BASE_URL="https://cloudbackup.datacomm.co.id/download/u/baas/4.0/${VERSION}"
  log_msg "Scanning installers at $BASE_URL ..."
  mapfile -t installers < <(wget -qO- "$BASE_URL/" |
                               grep -oP 'href="\K[^"]+\.(bin|exe|dmg|spk)(?=")' |
                               sort -V)
  [[ ${#installers[@]} -eq 0 ]] && { error "No installer found"; pause; return; }

  # 3. FILTER: Input keyword dari user
  echo ""
  echo "Available installers (${#installers[@]} total):"
  for i in "${!installers[@]}"; do
      echo "  $((i+1)). ${installers[$i]}"
  done

  echo ""
  read -rp "Enter filter keyword (or press Enter to show all): " keyword

  # Filter installer berdasarkan keyword (case-insensitive)
  if [[ -n "$keyword" ]]; then
      mapfile -t filtered < <(printf '%s\n' "${installers[@]}" | grep -i "$keyword")
      if [[ ${#filtered[@]} -eq 0 ]]; then
          warn "No installer matches keyword '$keyword', showing all installers"
          filtered=("${installers[@]}")
      else
          log_msg "Filtered by keyword '$keyword': ${#filtered[@]} result(s)"
      fi
  else
      filtered=("${installers[@]}")
  fi

  # Tampilkan hasil filter
  echo ""
  echo "Filtered installers (${#filtered[@]} found):"
  for i in "${!filtered[@]}"; do
      echo "  $((i+1)). ${filtered[$i]}"
  done

  # 4. Pilih nomor dari hasil filter
  [[ ${#filtered[@]} -eq 0 ]] && { error "No installer available to select"; pause; return; }

  while true; do
      read -rp "Select installer number: " num
      [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#filtered[@]} )) && break
      warn "Enter number between 1 and ${#filtered[@]}"
  done
  INSTALLER="${filtered[$((num-1))]}"
  log_msg "User selected installer: $INSTALLER"

  # 5. Token
  read -rp "Registration Token: " TOKEN
  [[ -z $TOKEN ]] && { error "Token required"; pause; return; }
  log_msg "Token accepted (hidden)"

  # 6. Folder & path download
  REAL_USER=${SUDO_USER:-$USER}
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
  TMP=${TMP_DIR:-$REAL_HOME/acronis-installer}
  mkdir -p "$TMP"
  BIN=$TMP/$INSTALLER
  URL="$BASE_URL/$INSTALLER"

  # 7. Download
  log_msg "Downloading installer to $BIN ..."
  (wget -qO "$BIN" "$URL" 2>&1 | tee -a "$LOG") & spinner $! "Downloading"
  [[ -f $BIN ]] || { error "Download failed"; log_msg "Download failed"; pause; return; }
  chmod +x "$BIN"
  log_msg "Download completed"

  # 8. Install
  log_msg "Running installer ..."
  "$BIN" -a --token="$TOKEN" > >(tee -a "$LOG") 2>&1 & spinner $! "Installing"
  local rc=$?
  if [[ $rc -eq 0 ]]; then
    success "Installation completed"
    log_msg "Installation completed successfully"
  else
    error "Installation failed (exit $rc)"
    log_msg "Installation failed (exit $rc)"
    pause
    return 1
  fi

  # 9. Hapus installer opsional
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
  warn "Starting uninstall..."
  /usr/lib/Acronis/BackupAndRecovery/uninstall/uninstall -a & spinner $! "Uninstalling"
  success "Uninstall finished"
  pause
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
  pause
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
  pause
}

##############  ACROPSH  ######################
run_acropsh() {
  info "Downloading acropsh..."
  wget -qO /tmp/acropsh.zip 'https://acronis.sharepoint.com/:u:/s/SupportShareExternal/SAT/EZdG6C6SzMZFiSbypQmTi6kB48MuOQxqfG8JoIvxw4dhnQ?e=zyelOA&download=1 '
  check_and_install_unzip
  unzip -q /tmp/acropsh.zip -d /tmp/acropsh
  python3 /tmp/acropsh/linux_installation_healthcheck/main.py
  success "acropsh finished"
  pause
}

##############  CLEANUP  ######################
cleanup() {
  info "Cleaning temporary files..."
  mapfile -t tmp < <(find /tmp -maxdepth 1 -type f -name 'cvt_*.log' -o -name 'acropsh_*.log' -o -name '*.zip' -o -name 'Linux64.zip')
  for f in "${tmp[@]}"; do rm -f "$f" && printf "."; done
  success "Cleanup done"
  pause
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
