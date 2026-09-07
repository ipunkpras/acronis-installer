#!/bin/bash
# Acronis Cyber Protect Agent Installer   •   dcloud.co.id
readonly VERSION="2.9.10"   # Semantic Versioning: MAJOR.MINOR.PATCH
# 2.9.10 — Check Components output compacted to fit one screen on short
#   terminals: feature dirs now ONE line (was 7), section separator dropped.
#   Symptom fixed: snapapi status + "Press any key" prompt scrolled off-screen.
# 2.9.9 — header polish + host info: updated-date/clock moved INSIDE the box
#   as a third centered line, pure ASCII (the old line below the box was
#   left-anchored and ran past the box edge); box width shrink-wraps to the
#   widest line (fixed 44 cols left a ragged right side); new status line
#   above Agent: hostname + primary-NIC IP (default-route source address)
# 2.9.8 — header truly symmetric on ALL terminals: emoji removed from the
#   box (its column width is font-dependent — the source of the ragged edge);
#   shield emoji now lives in the one-shot splash, box interior is pure ASCII
# 2.9.7 — header box symmetric (centered lines); blank line before agent
#   status; new portal connectivity status line (TCP probe :443, 3s timeout)
# 2.9.6 — no-flicker clock: menu painted once, clock line repainted in-place
#   every 30s via cursor moves (was 1s full clear+redraw = terminal glitch);
#   one-shot intro splash (shield arming pulse)
# 2.9.5 — all user-facing output English; menu items aligned with short
#   one-line descriptions (dim); Indonesian contact block translated
# 2.9.4 — menu polish: header last-updated month/year + live WIB clock
#   (1s redraw loop, keypress stops), Help/Exit separated into own misc
#   column, Help page gets contact emails
# 2.9.3 — cleanup fix: delete only the .bin + installer-tmp, not the whole
#   ~/acronis-installer folder — rm -rf $TMP removed the install LOG and
#   audit.log that tee was still writing to ("No such file or directory"
#   after "Installer deleted"), and wiped the audit trail every install
# 2.9.2 — manual mode fix: run .bin directly on the controlling tty instead
#   of piping through tee — Acronis' TUI wizard renders degenerate (tiny
#   dialog in top-left corner) when stdout/stderr is a pipe, not a terminal
# 2.9.1 — third mode "manual": guided portal/version/token/download flow
#   then runs the .bin WITHOUT -a — Acronis' own interactive setup wizard
#   (component checklist, F12 descriptions) drives the install
# 2.9.0 — dual mode: gui (interactive menu, default) + cli (automation:
#   ACRONIS_MODE=cli + ACRONIS_TOKEN/PORTAL/VERSION/COMPONENT/DEBUG/KEEP_BIN
#   env vars, zero prompts, proper exit codes, pause suppressed)
# 2.8.0 — multi-portal: portal picker (preset Datacomm + custom URL),
#   optional -C/--rain registration-server override (in options-file,
#   hidden from ps), version scan + installer download from chosen portal
# 2.7.0 — loading UX + components: real progress bar on downloads
#   (% [####----] got/total), ASCII spinner (braille broke on many fonts)
#   with elapsed time, mm:ss install heartbeat, [8] Check Components (v):
#   agent version, registered agents, feature dirs, snapapi module state
# 2.6.0 — install hardening (P1-P3): token in options-file (600, shredded
#   after — invisible in ps), component selection via --components-list/-i,
#   --tmp-dir into ~/acronis-installer, optional -d debug
# 2.5.3 — acropsh: TMPDIR=OUT_DIR (reports born in ~/acronis-installer, no
#   post-run mv); cleanup message reflects both paths
# 2.5.2 — help page fix: color vars now ANSI-C quoted ($'\033[..]m') so
#   heredoc renders colors instead of literal escape codes
# 2.5.1 — all outputs now go to ~/acronis-installer/ (real user's home):
#   CVT log, acropsh zip/report, install log+bin, audit copy. /var/log kept
# 2.5.0 — menu: "Cleanup Tmp" renamed "Clean Artifacts" (k), added Help (h)
#   page explaining every menu function; cleanup also removes kept .bin installers
# 2.4.3 — install: auto-select installer matching OS architecture
#   (x86_64/x86/arm64 via uname -m); manual keyword fallback kept
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
# 2.5.2: ANSI-C quoting -> real ESC chars at definition time.
# Reason: heredoc (help page) expands ${BOLD} literally without escape
# interpretation, printing raw \033 codes. echo -e / printf %b elsewhere
# treat already-real ESC chars identically, so this is safe everywhere.
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
BLUE=$'\033[34m'; MAGENTA=$'\033[35m'; CYAN=$'\033[36m'
BOLD=$'\033[1m'; WHITE=$'\033[37m'; RESET=$'\033[0m'; DIM=$'\033[2m'

# 2.8.0: multi-portal registry — "name|download_base|rain_url"
# rain_url empty = trust the .bin's injected registration server
PORTALS=(
  "Datacomm (cloudbackup.datacomm.co.id)|https://cloudbackup.datacomm.co.id/download/u/baas/4.0|"
)
DL_BASE="https://cloudbackup.datacomm.co.id/download/u/baas/4.0"

# 2.9.0: MODE — "gui" (default interactive menu) or "cli" (automation).
# CLI mode = no prompts: all install inputs come from ACRONIS_* env vars.
MODE=${ACRONIS_MODE:-gui}
[[ $MODE != cli && $MODE != gui && $MODE != manual ]] && MODE=gui

##############  UTILS  ########################
log() { echo -e "${2:-}${BOLD}${1}${RESET}"; }
success() { log "✅ ${1}" "$GREEN"; }
error() { log "❌ ${1}" "$RED"; }
warn()  { log "⚠️  ${1}" "$YELLOW"; }
info()  { log "ℹ️  ${1}" "$BLUE"; }

# spinner v3 (2.7.0): ASCII chars only (braille broke on many terminal
# fonts — PuTTY/Windows show boxes), plus elapsed seconds, line-clear \033[K
spinner() {
  local pid=$1 spin='-\|/' i=0 label=${2:-working} t0=$SECONDS
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r\033[K  %s %s ... %ds " "${spin:i++%4:1}" "$label" "$((SECONDS-t0))"
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
  [[ $MODE == cli || $MODE == manual ]] && return 0
  echo
  read -n1 -rp "$(echo -e "${YELLOW}Press any key to return to menu...${RESET}")"
  echo
}

# 2.4.0: persistent audit trail — every action + result lands in one log
AUDIT_LOG="/var/log/acronis-tools-$(hostname).log"   # root copy (2.5.1)
audit() {
  echo "[$(date '+%F %T')] $*" >> "$AUDIT_LOG"
  [[ -n ${OUT_DIR:-} && -d $OUT_DIR ]] && echo "[$(date '+%F %T')] $*" >> "$OUT_DIR/audit.log"
}

# 2.4.0: numbered step label for guided flows
step() { echo; echo -e "${BOLD}${CYAN}━━ Step $1: ${2}${RESET}"; }

# 2.5.1: per-user output directory — all tool outputs land in the
# real (sudo-invoking) user's ~/acronis-installer so they are visible
# over SFTP without root. Falls back to /root when no SUDO_USER.
out_dir() {
  local ru=${SUDO_USER:-$USER}
  local rh; rh=$(getent passwd "$ru" | cut -d: -f6)
  [[ -z $rh || $rh == /nonexistent ]] && rh=/root
  OUT_DIR="$rh/acronis-installer"
  mkdir -p "$OUT_DIR"
  chmod 755 "$OUT_DIR" 2>/dev/null || true
  echo "$OUT_DIR"
}
OUT_DIR=$(out_dir)
audit "output dir: $OUT_DIR"

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
# 2.9.9: locale-independent column counting (hoisted out of draw_box for reuse)
display_width() {
  local clean
  clean=$(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')
  # 2.9.8: count columns robustly — strip non-ASCII bytes first (the only
  # non-ASCII left in box lines is the • separator). wc -m counts BYTES in
  # C locale and codepoints in UTF-8; neither equals columns for •.
  # Column-truth: ASCII chars = 1 col; • = 1 col -> count = ASCII + non-ASCII
  # groups. Simpler: replace non-ASCII runs with a single char each.
  local ascii non
  ascii=$(printf '%s' "$clean" | LC_ALL=C grep -o '[ -~]' | wc -l)
  non=$(printf '%s' "$clean" | LC_ALL=C grep -oE '[^ -~]+' | wc -l)
  echo $((ascii + non))
}

draw_box() {
  local -a lines=("$@")
  # 2.9.9: width shrink-wraps to the widest line (fixed 44 clipped long
  # lines and left a ragged right side on short ones)
  local width=0 w ln
  for ln in "${lines[@]}"; do
    w=$(display_width "$ln")
    (( w > width )) && width=$w
  done
  (( width < 20 )) && width=20

  local border
  border=$(printf '─%.0s' $(seq 1 "$width"))
  printf "%b╭─%s─╮%b\n" "$CYAN" "$border" "$RESET"
  local pad padl
  for ln in "${lines[@]}"; do
    # 2.9.7: center each line — left pad split across both sides for a
    # symmetric header box (was left-anchored => ragged right side)
    pad=$((width - $(display_width "$ln")))
    [[ $pad -lt 0 ]] && pad=0
    padl=$((pad / 2))
    printf "%b│%b %*s%s%*s %b │%b\n" "$CYAN" "$RESET" "$padl" "" "$ln" $((pad - padl)) "" "$CYAN" "$RESET"
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

# 2.9.9: host identity — hostname + primary-NIC IP only (the NIC that owns
# the default route's source address), shown in the status block.
host_status_line() {
  local hn ip
  hn=$(hostname)
  ip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[0-9.]+')
  [[ -z $ip ]] && ip="no route"
  echo -e " ${BOLD}Host:${RESET} $hn   ${BOLD}IP:${RESET} $ip"
}

# 2.9.7: portal connectivity status — quick TCP probe (443) with short
# timeout, no wget/curl body fetch: menu stays snappy even if portal is down
portal_status_line() {
  local host="cloudbackup.datacomm.co.id"
  local ok
  if timeout 3 bash -c "exec 3<>/dev/tcp/${host}/443" 2>/dev/null; then
    ok=1
  else
    ok=0
  fi
  if [[ $ok == 1 ]]; then
    echo -e " ${GREEN}●${RESET} Portal: ${GREEN}reachable${RESET}   ${BOLD}https://${host}${RESET}"
  else
    echo -e " ${RED}○${RESET} Portal: ${RED}unreachable${RESET}   ${BOLD}https://${host}${RESET}"
  fi
}

##############  MAIN MENU  ####################
show_main_menu() {
  local UPDATED="Sep 2026"   # 2.9.4: month/year of the last tool update
  local key

  # 2.9.6: one-shot intro splash — shield "arming" pulse (suits a protection
  # tool): banner + growing cyan bars, then menu paints
  splash() {
    local i w
    clear
    echo
    printf '   🛡️\n\n'   # 2.9.8: shield lives in the splash now
    draw_box \
      'Acronis Cyber Protect Agent Tools' \
      "$VERSION • https://dcloud.co.id"
    echo
    for i in 1 2 3 4 5 6 7 8; do
      w=$((i * 4))
      printf '%b█%*s' "$CYAN" "$w" ''
      printf '%b\r' "$RESET"
      sleep 0.05
    done
    printf '%b%*s\n%b' "$CYAN" 32 '' "$RESET"
    sleep 0.30
  }

  # 2.9.6: menu painted ONCE; clock updated in-place via cursor move —
  # no clear+redraw each second => no glitch/flicker. Clock refresh: 30s.
  render_menu() {
    clear
    # 2.9.9: updated-date + live clock moved INSIDE the box as a third
    # centered line (was printed below the box, left-anchored, overflowing
    # past the right border). Pure ASCII per the 2.9.8 lesson.
    draw_box \
      'Acronis Cyber Protect Agent Tools' \
      "$VERSION • https://dcloud.co.id" \
      "Updated: $UPDATED - $(date '+%a %d %b %Y • %H:%M:%S') WIB"
    echo
    log "Choose action:" "$BOLD"

  # 2.9.5: aligned menu + one-line English descriptions per item
  printf " $GREEN[1] Install Agent       $YELLOW(i)$RESET ${DIM}guided multi-portal agent install$RESET\n"
  printf " $RED[2] Uninstall Agent     $YELLOW(u)$RESET ${DIM}remove agent (two-step confirm)$RESET\n"
  printf " $BLUE[3] Check Services      $YELLOW(s)$RESET ${DIM}service status + health verdict$RESET\n"
  printf " $MAGENTA[4] acropsh Tool        $YELLOW(a)$RESET ${DIM}official Acronis health check$RESET\n"
  printf " $CYAN[5] CVT Tool            $YELLOW(c)$RESET ${DIM}MSP port checker to portal$RESET\n"
  printf " $YELLOW[6] Clean Artifacts     $YELLOW(k)$RESET ${DIM}remove leftover tool files$RESET\n"
  printf " $CYAN[8] Check Components    $YELLOW(v)$RESET ${DIM}inventory installed components$RESET\n"

  # 2.9.4: Help & Exit in their own misc column (not operational items)
  printf "%b ╾───────┤ misc ├───────╼%b\n" "$CYAN" "$RESET"
  printf " $WHITE[7] Help                $YELLOW(h)$RESET ${DIM}usage guide + contacts$RESET\n"
  printf " $RED[0] Exit               $YELLOW(q)$RESET ${DIM}quit to the shell$RESET"


    printf "\n\n"          # 2.9.7: blank line between Exit and status block
    host_status_line      # 2.9.9: hostname + primary-NIC IP
    agent_status_line
    portal_status_line
    printf "\n"
  }

  splash
  # 2.9.6: clock redraw every 30s (was 1s) — glitch/flicker reduced 30x;
  # full repaint chosen over cursor-jump tricks (fragile in web terminals)
  while :; do
    render_menu
    if read -rp "Press key (shortcut in yellow): " -n1 -t 30 key; then
      echo
      break
    fi
  done
  case "${key,,}" in
    i|1) audit "MENU: install_agent start";  install_agent  && audit "ACTION install_agent: OK"   || { audit "ACTION install_agent: FAILED"; warn "Install finished with error"; };;
    u|2) audit "MENU: uninstall_agent start"; uninstall_agent && audit "ACTION uninstall_agent: OK" || { audit "ACTION uninstall_agent: FAILED"; warn "Uninstall finished with error"; };;
    s|3) audit "MENU: check_services"; check_services;;
    a|4) audit "MENU: acropsh start"; run_acropsh && audit "ACTION acropsh: OK" || { audit "ACTION acropsh: FAILED"; warn "acropsh finished with error"; };;
    c|5) audit "MENU: cvt start"; run_cvt_tool && audit "ACTION cvt: OK" || { audit "ACTION cvt: FAILED"; warn "CVT finished with error"; };;
    k|6) audit "MENU: cleanup artifacts"; cleanup;;
    h|7) audit "MENU: help"; show_help;;
    v|8) audit "MENU: check components"; check_components;;
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
# validated download: rc + size vs Content-Length, atomic (.tmp -> move)
# 2.7.0: real progress bar — background curl/wget + poll size vs expected,
# renders  % [####----] got/total (elapsed). Works even without numfmt.
download() {
  local url=$1 dest=$2 expected got rc pid t0 pct filled bar gots tots
  expected=$(curl -sIL --max-time 20 "$url" 2>/dev/null \
             | awk 'tolower($1) ~ /^http\// {ok = ($2 == 200)} tolower($1) ~ /^content-length:/ && ok {v=$2} END {print int(v)}' | tr -d '\r')
  if command -v curl >/dev/null 2>&1; then
    curl -fsL --retry 3 --connect-timeout 15 -o "$dest.tmp" "$url" & pid=$!
  else
    wget -q -O "$dest.tmp" "$url" & pid=$!
  fi
  t0=$SECONDS
  while kill -0 "$pid" 2>/dev/null; do
    got=$(stat -c%s "$dest.tmp" 2>/dev/null || echo 0)
    if [[ ${expected:-0} -gt 0 ]]; then
      pct=$(( got * 100 / expected )); (( pct > 100 )) && pct=100
      filled=$(( pct / 5 ))
      bar=$(printf '%*s' "$filled" '' | tr ' ' '#')$(printf '%*s' "$(( 20 - filled ))" '' | tr ' ' '-')
      gots=$(numfmt --to=iec "$got" 2>/dev/null || echo "${got}B")
      tots=$(numfmt --to=iec "$expected" 2>/dev/null || echo "${expected}B")
      printf "\r\033[K  %3d%% [%s] %s / %s (%ds) " "$pct" "$bar" "$gots" "$tots" "$((SECONDS-t0))"
    else
      gots=$(numfmt --to=iec "$got" 2>/dev/null || echo "${got}B")
      printf "\r\033[K  downloading ... %s (%ds) " "$gots" "$((SECONDS-t0))"
    fi
    sleep 1
  done
  wait "$pid"; rc=$?
  printf "\r\033[K"
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
  local LOG="$OUT_DIR/acronis-install-$(hostname)-$(date +%F-%H-%M).log"
  # root copy in /var/log kept for sysadmins; primary copy in user dir
  { echo "[$(date '+%F %T')] install started on $(hostname)" >> "/var/log/acronis-install-$(hostname)-$(date +%F).log"; } 2>/dev/null || true
  log_msg() { echo -e "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

  log_msg "=== Acronis Agent Installation Started ==="

  # 0. portal selection (2.8.0; 2.9.0 cli mode: ACRONIS_PORTAL / ACRONIS_RAIN)
  local DL RAIN=""
  if [[ $MODE == cli ]]; then
    # ACRONIS_PORTAL: preset name index ("1" = Datacomm) or full download-base URL
    local p_in=${ACRONIS_PORTAL:-1}
    if [[ $p_in =~ ^[0-9]+$ ]] && (( p_in >= 1 && p_in <= ${#PORTALS[@]} )); then
      IFS='|' read -r _ DL RAIN <<< "${PORTALS[$((p_in-1))]}"
    elif [[ $p_in == *"://"* ]]; then
      DL=${p_in%/}
      RAIN=${ACRONIS_RAIN%/}
    else
      error "ACRONIS_PORTAL must be a preset number (1) or a full URL"; log_msg "ERROR: bad ACRONIS_PORTAL"; return 1
    fi
    log_msg "Portal [cli]: $DL${RAIN:+ (reg: $RAIN)}"
    audit "portal[cli]: $DL reg=${RAIN:-bin-default}"
  else
  step 0 "Select portal"
  echo "  Available portals:"
  local p_i p_name
  for p_i in "${!PORTALS[@]}"; do
    p_name=${PORTALS[$p_i]%%|*}
    printf "   %d) %s\n" "$((p_i+1))" "$p_name"
  done
  echo "   $(( ${#PORTALS[@]} + 1 )). Custom portal (enter URLs)"
  local p_sel
  read -rp "Portal number [1]: " p_sel
  [[ -z $p_sel ]] && p_sel=1
  if [[ $p_sel =~ ^[0-9]+$ ]] && (( p_sel >= 1 && p_sel <= ${#PORTALS[@]} )); then
    IFS='|' read -r _ DL RAIN <<< "${PORTALS[$((p_sel-1))]}"
    log_msg "Portal: $DL"
    audit "portal: $DL"
  elif [[ $p_sel == $(( ${#PORTALS[@]} + 1 )) ]]; then
    read -rp "Download base URL (e.g. https://portal.example.com/download/u/baas/4.0): " DL
    [[ -z $DL ]] && { error "URL required"; pause; return 1; }
    DL=${DL%/}
    read -rp "Registration server override -C (Enter = use .bin built-in): " RAIN
    [[ -n $RAIN ]] && RAIN=${RAIN%/}
    log_msg "Portal: $DL${RAIN:+ (reg: $RAIN)}"
    audit "portal: custom $DL reg=${RAIN:-bin-default}"
  else
    error "Invalid selection"; pause; return 1
  fi
  fi
  # strip trailing slash for consistent URL building
  DL=${DL%/}

  # 1. choose version
  step 1 "Fetch available versions from the portal"
  log_msg "Fetching available versions ..."
  local page
  page=$(fetch_page "$DL/") || { error "Cannot reach $DL"; log_msg "ERROR: cannot reach $DL"; pause; return 1; }
  mapfile -t vers < <(grep -oP 'href="\K[0-9]+\.[0-9]+\.[0-9]+(?=/)' <<<"$page" | sort -uV)
  [[ ${#vers[@]} -eq 0 ]] && { error "No version found"; pause; return 1; }

  local DL_VERSION
  if [[ $MODE == cli ]]; then
    # cli: ACRONIS_VERSION = exact version, or "latest" (default = highest)
    local want=${ACRONIS_VERSION:-latest}
    if [[ $want == latest ]]; then
      DL_VERSION=${vers[-1]}
    else
      DL_VERSION=""
      local v
      for v in "${vers[@]}"; do [[ $v == "$want" ]] && DL_VERSION=$v; done
      [[ -z $DL_VERSION ]] && { error "Version $want not found on portal (available: ${vers[*]})"; log_msg "ERROR: version not found"; return 1; }
    fi
    log_msg "Version [cli]: $DL_VERSION"
  else
  echo "Available versions:"
  local i num
  for i in "${!vers[@]}"; do echo "  $((i+1)). ${vers[$i]}"; done
  while true; do
    read -rp "Select version number: " num
    [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#vers[@]} )) && break
    warn "Enter number between 1 and ${#vers[@]}"
  done
  DL_VERSION=${vers[$((num-1))]}
  log_msg "User selected version: $DL_VERSION"
  fi

  # 2. scan installer list
  step 2 "Scan installer files"
  local BASE_URL="$DL/$DL_VERSION"
  log_msg "Scanning installers at $BASE_URL ..."
  page=$(fetch_page "$BASE_URL/") || { error "Cannot reach $BASE_URL"; log_msg "ERROR: cannot reach $BASE_URL"; pause; return 1; }
  mapfile -t installers < <(grep -oP 'href="\K[^\"]+\.(bin|exe|dmg|spk)(?=\")' <<<"$page" | sort -uV)
  [[ ${#installers[@]} -eq 0 ]] && { error "No installer found"; pause; return 1; }

  # 3. auto-select installer by OS architecture (2.4.3)
  step 3 "Select installer file (auto-detected)"
  local arch; arch=$(uname -m)
  local match="" matches=()
  case "$arch" in
    x86_64|amd64) mapfile -t matches < <(printf '%s\n' "${installers[@]}" | grep -iE 'ForLinux_x86_64\.bin$' || true) ;;
    i[3-6]86|x86) mapfile -t matches < <(printf '%s\n' "${installers[@]}" | grep -iE 'ForLinux_x86\.bin$'   || true) ;;
    aarch64|arm64) mapfile -t matches < <(printf '%s\n' "${installers[@]}" | grep -iE 'ForLinux_arm64?\.bin$' || true) ;;
  esac

  if [[ ${#matches[@]} -eq 1 ]]; then
    match=${matches[0]}
    success "Auto-selected for $(uname -s) $arch: $match"
    log_msg "Auto-selected installer for arch $arch: $match"
  elif [[ ${#matches[@]} -gt 1 ]]; then
    if [[ $MODE == cli ]]; then
      match=${matches[0]}
      warn "Multiple installers for $arch — cli mode takes first: $match"
      log_msg "Auto (cli, multiple): $match"
    else
    warn "Multiple Linux installers for $arch — pick one:"
    local i
    for i in "${!matches[@]}"; do echo "  $((i+1)). ${matches[$i]}"; done
    local num
    while true; do
      read -rp "Select installer number: " num
      [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#matches[@]} )) && break
      warn "Enter number between 1 and ${#matches[@]}"
    done
    match=${matches[$((num-1))]}
    log_msg "User selected installer: $match"
    fi
  else
    if [[ $MODE == cli ]]; then
      error "No installer for arch '$arch' on this portal — cannot continue headless"
      log_msg "ERROR: no installer for arch $arch (cli)"
      return 1
    fi
    # no arch match (unsupported arch / no Linux build) — manual fallback
    warn "No automatic match for arch '$arch' — manual selection:"
    echo ""
    echo "Available installers (${#installers[@]} total):"
    local i
    for i in "${!installers[@]}"; do echo "  $((i+1)). ${installers[$i]}"; done
    local keyword num filtered=()
    read -rp "Enter filter keyword (or press Enter to show all): " keyword
    filtered=("${installers[@]}")
    if [[ -n "${keyword:-}" ]]; then
      mapfile -t filtered < <(printf '%s\n' "${installers[@]}" | grep -i "$keyword" || true)
      [[ ${#filtered[@]} -eq 0 ]] && { warn "No installer matches keyword '$keyword', showing all installers"; filtered=("${installers[@]}"); }
    fi
    echo ""
    echo "Filtered installers (${#filtered[@]} found):"
    for i in "${!filtered[@]}"; do echo "  $((i+1)). ${filtered[$i]}"; done
    [[ ${#filtered[@]} -eq 0 ]] && { error "No installer available to select"; pause; return 1; }
    while true; do
      read -rp "Select installer number: " num
      [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#filtered[@]} )) && break
      warn "Enter number between 1 and ${#filtered[@]}"
    done
    match=${filtered[$((num-1))]}
    log_msg "User selected installer (manual): $match"
  fi
  local INSTALLER=$match

  # 5. token (2.9.0 cli: ACRONIS_TOKEN)
  step 4 "Registration token"
  local TOKEN
  [[ -n $DL && $DL != https://cloudbackup.datacomm.co.id* ]] && \
    info "Make sure the token was issued by THIS portal's console — tokens do not transfer between portals."
  if [[ $MODE == cli ]]; then
    TOKEN=$ACRONIS_TOKEN
    [[ -z $TOKEN ]] && { error "ACRONIS_TOKEN required in cli mode"; log_msg "ERROR: no token"; return 1; }
  else
    read -rp "Registration Token: " TOKEN
    [[ -z $TOKEN ]] && { error "Token required"; pause; return 1; }
  fi
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

  # 7b. component selection (P2, v2.6.0) — from the .bin itself
  #      manual mode skips it: the installer wizard shows its own checklist
  step 5 "Select components (from installer)"
  local comps=()
  [[ $MODE != manual ]] && mapfile -t comps < <("$BIN" --components-list 2>/dev/null | grep -viE 'trueimage|permission denied' || true)
  local comp_arg=""
  if [[ ${#comps[@]} -gt 0 ]]; then
    if [[ $MODE == cli ]]; then
      # 2.9.0: ACRONIS_COMPONENT = exact component id (e.g. AgentForProxmox), empty = standard
      if [[ -n ${ACRONIS_COMPONENT:-} ]]; then
        local cfound=""
        local c
        for c in "${comps[@]}"; do [[ $c == "$ACRONIS_COMPONENT" ]] && cfound=$c; done
        [[ -z $cfound ]] && { error "ACRONIS_COMPONENT '$ACRONIS_COMPONENT' not in installer (available: ${comps[*]})"; log_msg "ERROR: bad component"; return 1; }
        comp_arg="--id=$cfound"
        log_msg "Component [cli]: $cfound"
      else
        log_msg "Component [cli]: standard (no --id)"
      fi
    else
    echo "  Available components in this installer:"
    for i in "${!comps[@]}"; do printf "   %d) %s\n" "$((i+1))" "${comps[$i]}"; done
    echo "  Enter = standard agent (BackupAndRecovery) — recommended for most hosts"
    local cn
    read -rp "Install component number [default: standard]: " cn
    if [[ $cn =~ ^[0-9]+$ && $cn -ge 1 && $cn -le ${#comps[@]} ]]; then
      comp_arg="--id=${comps[$((cn-1))]}"
      log_msg "Selected component: ${comps[$((cn-1))]}"
    else
      log_msg "Standard agent install (no --id)"
    fi
    fi
  else
    log_msg "components-list unavailable — standard agent install"
  fi

  # 8. install — live output + heartbeat, rc ASLI
  step 6 "Install (live output, APT phase may take 10-30 min)"
  log_msg "Running installer ..."
  export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a

  # P1 (v2.6.0): token goes into an options-file (mode 600) instead of the
  # command line — invisible in `ps` during the long install. Shredded after.
  local OPTFILE="$TMP/.token-optfile"
  umask 077
  { printf -- "--token=%s\n" "$TOKEN"
    [[ -n $RAIN ]] && printf -- "--rain=%s\n" "$RAIN"
  } > "$OPTFILE"
  chmod 600 "$OPTFILE"

  # P3 (v2.6.0): installer temp files stay in our dir, not /var/tmp
  local BIN_TMP="$TMP/installer-tmp"
  mkdir -p "$BIN_TMP"

  # P3: optional verbose debug log (cli: ACRONIS_DEBUG=1)
  local dbg; local dbg_arg=""
  if [[ $MODE == cli ]]; then
    [[ ${ACRONIS_DEBUG:-0} == 1 ]] && { dbg_arg="-d"; log_msg "Debug mode [cli]: on"; }
  else
    read -rp "Enable installer verbose debug log? [y/N] " dbg
    [[ $dbg =~ ^[Yy]$ ]] && { dbg_arg="-d"; log_msg "Debug mode: on"; }
  fi

  info "Installer output shown live. APT prereq phase may take 10-30 min — do not Ctrl-C."
  # 2.9.1: manual mode drops -a so the installer's own TUI wizard shows
  # (component checklist, F12 descriptions). Token still goes through the
  # options-file so it never appears on the command line.
  local AUTO=-a
  [[ $MODE == manual ]] && AUTO=""
  # 2.9.2: manual mode needs a REAL terminal — piping through tee makes the
  # installer's TUI wizard render degenerate (tiny dialog in a corner).
  # Run it directly on the controlling tty; progress messages also off.
  local wait_rc
  if [[ $MODE == manual ]]; then
    "$BIN" $AUTO --options-file="$OPTFILE" --tmp-dir="$BIN_TMP" $comp_arg $dbg_arg
    wait_rc=$?
  else
  local pid=$! t0=$SECONDS
  while kill -0 "$pid" 2>/dev/null; do
    sleep 30
    if kill -0 "$pid" 2>/dev/null; then
      local el=$((SECONDS-t0))
      info "installer running ... $((el/60))m$((el%60))s (APT phase can take 10-30 min)"
    fi
  done
  wait "$pid"
  wait_rc=$?
  fi
  local rc=$wait_rc

  # token file no longer needed — shred it
  command -v shred >/dev/null 2>&1 && shred -u "$OPTFILE" 2>/dev/null || rm -f "$OPTFILE"

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

  # 9. optional delete (cli: ACRONIS_KEEP_BIN=1 keeps, default deletes)
  step 7 "Cleanup installer file"
  local del
  clean_bin() {
    # 2.9.3: delete only the .bin + its tmp dir — NOT the whole folder.
    # The folder also holds the install LOG + audit.log that log_msg is
    # still writing to (tee died with "No such file or directory" when
    # rm -rf $TMP removed them mid-write).
    rm -f "$TMP"/CyberProtect*.bin
    rm -rf "$TMP/installer-tmp"
  }
  if [[ $MODE == cli ]]; then
    if [[ ${ACRONIS_KEEP_BIN:-0} == 1 ]]; then
      log_msg "Installer kept at $TMP"
    else
      clean_bin
      log_msg "Installer deleted [cli default]"
    fi
  else
    read -rp "Delete installer? [y/N] " del
    if [[ $del =~ ^[Yy]$ ]]; then
      clean_bin
      log_msg "Installer deleted"
    else
      log_msg "Installer kept at $TMP"
    fi
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

##############  COMPONENT CHECK  #############
# 2.7.0: inventory of installed Acronis components — agent version from
# installer.version, registered agents from the aakore registry XML
# (AgentInfo DisplayName+Version entries), snapapi kernel module state.
check_components() {
  echo
  log "Installed Acronis Components" "$BOLD"
  # 2.9.10: separator dropped — every saved line keeps snapapi + prompt on-screen

  # agent version
  local vf=/opt/acronis/var/aakore/installer.version av="(not installed)"
  if [[ -r $vf ]]; then
    local maj min pat build
    maj=$(grep -oP 'MAJOR_VERSION=\K[0-9]+' "$vf" 2>/dev/null)
    min=$(grep -oP 'MINOR_VERSION=\K[0-9]+' "$vf" 2>/dev/null)
    pat=$(grep -oP 'PATCH_VERSION=\K[0-9]+' "$vf" 2>/dev/null)
    build=$(grep -oP 'BUILD_NUMBER=\K[0-9]+' "$vf" 2>/dev/null)
    [[ -n $maj ]] && av="$maj.$min.$pat (build $build)"
  fi
  echo -e "  Agent version: ${BOLD}$av${RESET}"

  # registered agents from aakore registry XML
  local regf=/usr/lib/Acronis/BackupAndRecoveryAgent.reg
  if [[ -r $regf ]]; then
    echo
    echo -e "  ${BOLD}Registered agents:${RESET}"
    awk '
      /MachineManager\\AgentInfo\\/ { ai=1 }
      ai && /<name>DisplayName<\/name>/ { dn=1 }
      dn && /<value>/ { gsub(/.*<value>|<\/value>.*/,""); name=$0; dn=0 }
      ai && /<name>Version<\/name>/ { vn=1 }
      vn && /<value>/ { gsub(/.*<value>|<\/value>.*/,""); ver=$0; vn=0 }
      name != "" && ver != "" {
        printf "   \033[32m✓\033[0m %-32s %s\n", name, ver
        name=""; ver=""; ai=0
      }' "$regf" | head -20
  else
    echo -e "  No agent registry found (agent not installed)"
  fi

  # feature directories (optional components present on disk)
  # 2.9.10: one-line listing (was 7 lines + separators — pushed snapapi
  # status and the pause prompt off-screen on short terminals)
  echo -e "  ${BOLD}Feature dirs (/usr/lib/Acronis):${RESET}"
  local f flist=""
  for f in BackupAndRecoveryAgent BackupAndRecovery CPS Schedule CommandLineTool VirtualWare PyTools; do
    if [[ -d /usr/lib/Acronis/$f ]]; then
      flist+="${GREEN}✓${RESET}$f "
    else
      flist+="${RED}✗${RESET}$f "
    fi
  done
  echo -e "  $flist"

  # snapapi kernel module
  echo
  echo -e "  ${BOLD}Kernel module (snapapi):${RESET}"
  if lsmod 2>/dev/null | grep -q snapapi; then
    local modver
    modver=$(modinfo snapapi26 2>/dev/null | awk -F': +' '/^version:/{print $2}')
    echo -e "   ${GREEN}●${RESET} loaded in kernel${modver:+ (v$modver)}"
  elif command -v dkms >/dev/null 2>&1 && dkms status 2>/dev/null | grep -qi snapapi; then
    echo -e "   ${YELLOW}○${RESET} built via DKMS but not loaded — reboot may be needed"
  else
    echo -e "   ${RED}✗${RESET} not loaded — check: lsmod | grep snapapi"
  fi

  audit "components checked"
  pause
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
  local output_file="$OUT_DIR/cvt_$(hostname)_$(date +%F).log"

  info "Downloading CVT..."
  if ! download "https://dl.acronis.com/u/support/KB/Linux64.zip" "$OUT_DIR/Linux64.zip"; then
    error "CVT download failed (network?)"
    pause
    return 1
  fi
  check_and_install_unzip || { pause; return 1; }
  rm -rf "$OUT_DIR/cvt_tool"
  unzip -q -o "$OUT_DIR/Linux64.zip" -d "$OUT_DIR/cvt_tool" || { error "unzip failed"; pause; return 1; }
  chmod +x "$OUT_DIR/cvt_tool/msp_port_checker_packed.exe"

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
  printf '%s\n' "$PASSWORD" | timeout 300 "$OUT_DIR/cvt_tool/msp_port_checker_packed.exe" -u="$LOGIN" -h=cloudbackup.datacomm.co.id 2>&1 | tee "$output_file"
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
  local zip_file="$OUT_DIR/acropsh_$(date +%s).zip"
  local extract_dir="$OUT_DIR/acropsh_x_$(date +%s)"

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
    if [[ -f "$OUT_DIR/acropsh.zip" ]]; then
      zip_file="$OUT_DIR/acropsh.zip"
      info "Using $OUT_DIR/acropsh.zip (manual download)"
    elif [[ -f /tmp/acropsh.zip ]]; then
      zip_file=/tmp/acropsh.zip
      info "Using /tmp/acropsh.zip (manual download, legacy path)"
    else
      error "Download failed (HTTP $code — link requires auth / expired)"
      info "Workaround: download manually via browser, save as $OUT_DIR/acropsh.zip, then rerun this menu item."
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

  # 2.5.3: Python tempfile defaults to /tmp — point TMPDIR at OUT_DIR so
  # the HTML report is born inside ~/acronis-installer, no mv needed later
  export TMPDIR="$OUT_DIR"
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
  # 2.5.3: TMPDIR=OUT_DIR means new reports are born in OUT_DIR already;
  # /tmp scan kept only for legacy reports from older tool versions
  report=$(ls -t "$OUT_DIR"/*-service_summary.html 2>/dev/null | head -n1)
  [[ -z $report ]] && report=$(ls -t /tmp/*-service_summary.html 2>/dev/null | head -n1)
  if [[ -n $report ]]; then
    # 2.5.1: move into ~/acronis-installer and hand ownership to the real user
    local ru=${SUDO_USER:-$USER}
    local moved="$report"
    [[ $report == "$OUT_DIR"/* ]] || { moved="$OUT_DIR/$(basename "$report")"; mv -f "$report" "$moved"; }
    chmod 644 "$moved"
    getent passwd "$ru" >/dev/null 2>&1 && chown "$ru:" "$moved" 2>/dev/null
    info "Report (fetchable via SFTP): $moved"
    audit "acropsh report: $moved"
  else
    report="$OUT_DIR"
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

##############  HELP  #######################
show_help() {
  clear
  # 2.9.9: pure-ASCII help header (emoji width broke box alignment)
  draw_box \
    'Acronis AIO Tools - Help' \
    "$VERSION • press any key in menu to return"
  echo
  cat <<HELP
${BOLD}[1] Install Agent${RESET} (i)
   Guided install, multi-portal. Modes (ACRONIS_MODE):
   gui (default, unattended -a install), manual (guided download then
   Acronis' own interactive setup wizard — component checklist, F12),
   cli (headless automation via ACRONIS_* env vars, exit codes for
   CI/Ansible). See README for the full variable table. Pick the portal first (Datacomm
   preset, or a custom one with your own download base URL and optional
   registration-server override -C). The tool then fetches the version
   list from that portal, auto-selects the installer for your OS
   architecture, asks for the registration token (kept in a mode-600
   options-file — never visible in ps; the -C override also goes there),
   lets you pick optional components (MySQL/Oracle/Proxmox/PCS agents),
   then installs with live output + 30s heartbeat. Optional verbose
   debug log. Log + downloaded installer: ~/acronis-installer/

${BOLD}[2] Uninstall Agent${RESET} (u)
   Two-step confirmation (y/N, then type UNINSTALL) after showing a
   service summary table. Uses Acronis' own uninstaller.

${BOLD}[3] Check Services${RESET} (s)
   Colored status table for aakore / acronis_mms / acronis_schedule /
   acronis_kmod_service + overall health verdict.

${BOLD}[4] acropsh Tool${RESET} (a)
   Downloads and runs the official Acronis Linux health-check
   (linux_installation_healthcheck). Report lands in
   ~/acronis-installer/ (chmod 644, owned by you)

${BOLD}[5] CVT Tool${RESET} (c)
   MSP Port Checker — verifies required ports to
   cloudbackup.datacomm.co.id. Password input is hidden (never echoed).
   Log: ~/acronis-installer/cvt_<hostname>_<date>.log

${BOLD}[6] Clean Artifacts${RESET} (k)
   Removes leftover files this tool created: CVT logs/zips, acropsh
   archives, port-checker download and kept .bin installers — from both
   ~/acronis-installer/ and legacy /tmp. Nothing else is touched.

${BOLD}[8] Check Components${RESET} (v)
   Inventory of installed Acronis components: agent version, registered
   agents with versions, feature directories, and snapapi kernel module
   state — useful to verify what an install actually put on the machine.

${BOLD}[7] Help${RESET} (h)
   This page.

${BOLD}[0] Exit${RESET} (q)
   Quit to the shell.

${BOLD}Audit trail:${RESET} every action is logged to
   ~/acronis-installer/audit.log (+ /var/log copy for root)

${BOLD}Need help?${RESET}
   Having trouble using this tool? Contact:
   ${CYAN}ipunk.prasetyo@datacomm.co.id${RESET}
   ${CYAN}cloudoperation.engineer@datacomm.co.id${RESET}
HELP
  pause
}
##############  CLEANUP  ######################
cleanup() {
  info "Cleaning tool artifacts (~/.acronis-installer + legacy /tmp)..."
  # ponytail: narrow patterns + parens (find precedence) — never touch other zips
  find /tmp -maxdepth 1 -type f \
       \( -name 'cvt_*.log' -o -name 'acropsh_*.log' -o -name 'acropsh_*.zip' \
          -o -name 'Linux64.zip' -o -name 'CyberProtect_AgentFor*.bin' \) -print -delete 2>/dev/null
  # v2.5.1 artifacts now live in ~/acronis-installer — clean same patterns there
  find "$OUT_DIR" -maxdepth 1 -type f \
       \( -name 'cvt_*.log' -o -name 'acropsh_*.log' -o -name 'acropsh_*.zip' \
          -o -name 'acropsh_*.bin' -o -name 'Linux64.zip' \
          -o -name 'CyberProtect_AgentFor*.bin' \) -print -delete 2>/dev/null
  rm -rf "$OUT_DIR/installer-tmp" "$OUT_DIR/cvt_tool" 2>/dev/null
  success "Artifacts cleaned"
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

##############  MANUAL INSTALL  ############
# 2.9.1: manual mode = guided download + installer's own interactive TUI.
# Uses the SAME interactive prompts as GUI mode (portal, version, token) —
# only the install step differs: no -a, so Acronis' wizard (like the
# component checklist with F12 help, Tab/Space navigation) appears.
manual_install() {
  local BIN_HINT=${ACRONIS_BIN:-}
  # optional: run an already-downloaded .bin directly
  if [[ -n $BIN_HINT && -f $BIN_HINT ]]; then
    info "Using provided .bin: $BIN_HINT (ACRONIS_BIN)"
    audit "manual mode: direct .bin $BIN_HINT"
    "$BIN_HINT"
    return $?
  fi
  MODE=manual
  install_agent
}

##############  MAIN  #######################
# 2.9.0: cli mode — run install headless then exit (for automation).
# usage:
#   ACRONIS_MODE=cli ACRONIS_TOKEN=xxx [options] sudo -E ./installer-acronis.sh
#   ACRONIS_MODE=manual [ACRONIS_BIN=/path/to/downloaded.bin] sudo -E ./installer-acronis.sh
# options:
#   ACRONIS_PORTAL    1 = Datacomm preset | full download-base URL (default 1)
#   ACRONIS_RAIN      reg-server override -C (only with URL portal)
#   ACRONIS_VERSION   exact version | latest (default latest)
#   ACRONIS_COMPONENT component id e.g. AgentForProxmox (default standard)
#   ACRONIS_DEBUG     1 = installer -d verbose
#   ACRONIS_KEEP_BIN 1 = keep downloaded .bin (default delete)
if [[ $MODE == manual ]]; then
  # 2.9.1: manual mode — run the Acronis installer .bin directly so its own
  # interactive TUI (component checklist, F12 descriptions, Tab/Space) shows,
  # with the same guided setup as GUI mode (portal, version, arch, download
  # with progress bar, token hidden in options-file) — but install itself is
  # the installer's native setup wizard, not unattended -a.
  manual_install
  exit $?
fi

if [[ $MODE == cli ]]; then
  [[ $EUID -ne 0 ]] && { error "cli mode must run as root (sudo -E)"; exit 1; }
  if install_agent; then
    audit "cli install: OK"
    exit 0
  else
    audit "cli install: FAILED"
    exit 1
  fi
fi

##############  MAIN LOOP  ####################
while true; do
  show_main_menu
done
