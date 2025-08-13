#!/bin/bash
# Script instalasi dan uninstall Acronis Cyber Protect Agent - Datacomm Cloud Backup

# Loading Animation Function
loading() {
    local duration=$1
    local end=$((SECONDS + duration))
    local i=0
    local spinner=("🌑" "🌒" "🌓" "🌔" "🌕" "🌖" "🌗" "🌘")
    
    printf "Please wait"
    
    # Loading Function
    while [ $SECONDS -lt $end ]; do
        printf "\rPlease wait %s" "${spinner[i]}"
        ((i=(i+1)%8))
        sleep 0.3
    done
    printf "\n"
}

# Uninstall Function
uninstall_agent() {
    echo "⚠️ Starting uninstall process of Acronis Agent..." 
    loading 3
    /usr/lib/Acronis/BackupAndRecovery/uninstall/uninstall -a
    if [[ $? -ne 0 ]]; then
        echo "❌ Uninstallation failed."
    else
        echo "✅ Uninstallation finished."
    fi
}

# === Configuration ===
BASE_URL="https://cloudbackup.datacomm.co.id/download/u/baas/4.0"
DEFAULT_VERSION="25.6.40492"
INSTALLER_NAME="CyberProtect_AgentForLinux_x86_64.bin"

# === Root Checking ===
if [[ $EUID -ne 0 ]]; then
   echo '❌ Please run with "Root" access!!!'
   exit 1
fi

# === Checking Acronis Services===
check_services() {
    echo ""
    echo "🔎 Checking Acronis service status..."
    loading 3
    # Checking aakore service
    if systemctl is-active --quiet aakore; then
        echo "1. aakore: ✅ Running"
    else
        echo "1. aakore: ⚠️  Not Running/Not Found"
    fi

    # Checking acronis_mms service
    if systemctl is-active --quiet acronis_mms; then
        echo "2. acronis_mms: ✅ Running"
    else
        echo "2. acronis_mms: ⚠️  Not Running/Not Found"
    fi
}

# Banner and menu
echo "╔═════════════════════════════════════════════╗"
echo "║        ACRONIS CYBER PROTECT SCRIPT         ║"
echo "║---------------------------------------------║"
echo "║ Dev : https://github.com/ipunkpras          ║"
echo "║ Org : Dcloud                                ║"
echo "║>> v1.0 | 🌐 ipunkpras.my.id | JKT,ID 2025 <<║"
echo "╚═════════════════════════════════════════════╝"
echo ""
echo "Choose Action:"
echo "[1] Install Acronis Agent"
echo "[2] Uninstall Acronis Agent"
echo "[3] Check Acronis Services"
echo "[0] Cancel / Exit"
read -rp "Enter the options (0/1/2/3): " ACTION

case "$ACTION" in
    1)
        echo "🔹 Start the agent installation process..."
        ;; 
    2)
        uninstall_agent
        exit 0
        ;;
    3)
        check_services
        exit 0
        ;;
    0)
        echo "❌ Action has been canceled. Byeee..."
        exit 0
        ;;
    *)
        echo "❌ Input not valid. Byeee..."
        exit 1
        ;;
esac

# === Input from user ===
read -rp "Please input the Registration Token: " REGISTRATION_TOKEN
read -rp "Enter path temporary folder (default: ~/acronis-installer): " TMP_DIR
read -rp "Enter agent version Acronis (default: $DEFAULT_VERSION): " VERSION

# === Validation token ===
if [[ -z "$REGISTRATION_TOKEN" ]]; then
    echo "❌ Tokens cannot be empty."
    exit 1
fi

# if the folder is empty, set default.
if [[ -z "$TMP_DIR" ]]; then
    TMP_DIR="~/acronis-installer"
fi

# If the version is empty, use the default
if [[ -z "$VERSION" ]]; then
    VERSION="$DEFAULT_VERSION"
fi

ACRONIS_URL="$BASE_URL/$VERSION/$INSTALLER_NAME"
INSTALLER_PATH="$TMP_DIR/$INSTALLER_NAME"

# Make sure the temporary folder exists
echo "[1/5] Create a temporary folder in $TMP_DIR..."
mkdir -p "$TMP_DIR"
loading 3
if [[ $? -ne 0 ]]; then
    echo "❌ Failed to create folder $TMP_DIR"
    exit 1
fi

echo "[2/5] Download installer Acronis..."
curl -fLo "$INSTALLER_PATH" "$ACRONIS_URL"
loading 3
if [[ $? -ne 0 ]]; then
    echo "❌ Installer download failed. Check the URL or internet connection."
    exit 1
fi

echo "[3/5] Granting execution rights to the installer..."
chmod +x "$INSTALLER_PATH"
loading 3

echo "[4/5] Running the agent installation..."
"$INSTALLER_PATH" -a --token="$REGISTRATION_TOKEN"
loading 3
if [[ $? -ne 0 ]]; then
    echo "❌ Installation failed. Check your token or internet connection."
    exit 1
fi

# Check service status after installation
echo "[5/5] Checking service status..."
echo "--- Status aakore ---"
systemctl status aakore --no-pager || echo "Service aakore not found."
echo "--- Status acronis_mms ---"
systemctl status acronis_mms --no-pager || echo "Service acronis_mms not found."

# Confirmation to delete the installer
read -rp "Are you sure to delete the installer? (y/n): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm -rf "$TMP_DIR"
    echo "🗑️ Acronis Agent installer file has been deleted."
else
    echo "ℹ️ Acronis Agent installer file has been saved in: $TMP_DIR"
fi

echo "✅ Installation has been completed. Machine has been listed on Portal Acronis."

