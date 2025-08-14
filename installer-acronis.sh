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

# Tool Function: Run acropsh tool
run_acropsh() {
    echo "🔹 Installing Python3 if necessary and running acropsh tool..."

    # Step 1: Check if both aakore and acronis_mms services are running
    echo "🔎 Checking if Acronis services are installed and running..."
    
    if ! systemctl is-active --quiet aakore || ! systemctl is-active --quiet acronis_mms; then
        echo "❌ One or both services (aakore and acronis_mms) are not running. Exiting script."
        return 0  # Return to menu without executing the script
    fi

    # Step 2: Check if python3 is installed
    echo "Checking if Python3 is installed..."
    
    # Function to check the package manager
    check_package_manager() {
        if command -v apt &> /dev/null; then
            PACKAGE_MANAGER="apt"
        elif command -v yum &> /dev/null; then
            PACKAGE_MANAGER="yum"
        elif command -v dnf &> /dev/null; then
            PACKAGE_MANAGER="dnf"
        elif command -v zypper &> /dev/null; then
            PACKAGE_MANAGER="zypper"
        else
            echo "❌ Unknown package manager. This script supports apt, yum, dnf, and zypper."
            exit 1
        fi
    }

    # Check if python3 is installed and install it if needed
    if ! command -v python3 &> /dev/null
    then
        echo "Python3 is not installed."
        # Detect package manager
        check_package_manager
        
        case "$PACKAGE_MANAGER" in
            "apt")
                read -p "Do you want to install Python3 using apt? (y/n): " INSTALL_CONFIRMATION
                if [[ "$INSTALL_CONFIRMATION" == "y" || "$INSTALL_CONFIRMATION" == "Y" ]]; then
                    sudo apt update
                    sudo apt install -y python3
                else
                    echo "Python3 installation was skipped. Exiting script."
                    exit 1
                fi
                ;;
            "yum")
                read -p "Do you want to install Python3 using yum? (y/n): " INSTALL_CONFIRMATION
                if [[ "$INSTALL_CONFIRMATION" == "y" || "$INSTALL_CONFIRMATION" == "Y" ]]; then
                    sudo yum install -y python3
                else
                    echo "Python3 installation was skipped. Exiting script."
                    exit 1
                fi
                ;;
            "dnf")
                read -p "Do you want to install Python3 using dnf? (y/n): " INSTALL_CONFIRMATION
                if [[ "$INSTALL_CONFIRMATION" == "y" || "$INSTALL_CONFIRMATION" == "Y" ]]; then
                    sudo dnf install -y python3
                else
                    echo "Python3 installation was skipped. Exiting script."
                    exit 1
                fi
                ;;
            "zypper")
                read -p "Do you want to install Python3 using zypper? (y/n): " INSTALL_CONFIRMATION
                if [[ "$INSTALL_CONFIRMATION" == "y" || "$INSTALL_CONFIRMATION" == "Y" ]]; then
                    sudo zypper install -y python3
                else
                    echo "Python3 installation was skipped. Exiting script."
                    exit 1
                fi
                ;;
        esac
    else
        echo "Python3 is already installed."
    fi

    # Step 3: Download the script from the provided URL
    echo "Downloading the acropsh tool script..."
    wget "https://acronis.sharepoint.com/:u:/s/SupportShareExternal/SAT/EZdG6C6SzMZFiSbypQmTi6kB48MuOQxqfG8JoIvxw4dhnQ?e=zyelOA&download=1" -O /tmp/acronis_script.zip

    # Step 4: Copy the .zip archive to the required Linux machine and unpack it
    echo "Unpacking the .zip archive..."
    unzip /tmp/acronis_script.zip -d /tmp/acronis_script

    # Step 5: Execute the acropsh tool
    echo "Running the acropsh tool..."
    cd /tmp/acronis_script/linux_installation_healthcheck/
    sudo acropsh main.py

    # Step 6: Confirm if user wants to delete the extracted files
    read -p "Do you want to delete the extracted files from /tmp/acronis_script? (y/n): " DELETE_CONFIRMATION
    if [[ "$DELETE_CONFIRMATION" == "y" || "$DELETE_CONFIRMATION" == "Y" ]]; then
        echo "Deleting the extracted files..."
        rm -rf /tmp/acronis_script
        echo "Extracted files deleted."
    else
        echo "The extracted files were not deleted."
    fi
}

# Banner and menu
display_menu() {
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
    echo "[4] Run acropsh Tool"
    echo "[0] Cancel / Exit"
    read -rp "Enter the options (0/1/2/3/4): " ACTION
}

# Main Menu Loop
while true; do
    display_menu
    
    case "$ACTION" in
        1)
            echo "🔹 Start the agent installation process..."
            ;; 
        2)
            uninstall_agent
            ;;
        3)
            check_services
            ;;
        4)
            run_acropsh
            ;;
        0)
            echo "❌ Action has been canceled. Byeee..."
            exit 0
            ;;
        *)
            echo "❌ Input not valid. Please choose again."
            ;;
    esac
done
