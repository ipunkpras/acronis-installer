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

# CVT Tool Function
run_cvt_tool() {
    echo "🔹 Running CVT Tool..."
    
    # Step 1: Download the Linux Connection Verification Tool (64bit)
    echo "🔎 Downloading the Linux Connection Verification Tool..."
    wget https://dl.acronis.com/u/support/KB/Linux64.zip -O /tmp/Linux64.zip

    # Unpack the downloaded file
    echo "🔎 Unpacking the downloaded ZIP file..."

    # Check if unzip is installed
    if ! command -v unzip &> /dev/null; then
        echo "❌ unzip not found. Attempting to install..."
        # Detect package manager
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

        # Prompt for user input to install unzip
        case "$PACKAGE_MANAGER" in
            "apt")
                read -p "Do you want to install unzip using apt? (y/n): " INSTALL_CONFIRMATION
                if [[ "$INSTALL_CONFIRMATION" == "y" || "$INSTALL_CONFIRMATION" == "Y" ]]; then
                    sudo apt update && sudo apt install -y unzip
                else
                    echo "Installation of unzip was skipped. Exiting script."
                    exit 1
                fi
                ;;
            "yum")
                read -p "Do you want to install unzip using yum? (y/n): " INSTALL_CONFIRMATION
                if [[ "$INSTALL_CONFIRMATION" == "y" || "$INSTALL_CONFIRMATION" == "Y" ]]; then
                    sudo yum install -y unzip
                else
                    echo "Installation of unzip was skipped. Exiting script."
                    exit 1
                fi
                ;;
            "dnf")
                read -p "Do you want to install unzip using dnf? (y/n): " INSTALL_CONFIRMATION
                if [[ "$INSTALL_CONFIRMATION" == "y" || "$INSTALL_CONFIRMATION" == "Y" ]]; then
                    sudo dnf install -y unzip
                else
                    echo "Installation of unzip was skipped. Exiting script."
                    exit 1
                fi
                ;;
            "zypper")
                read -p "Do you want to install unzip using zypper? (y/n): " INSTALL_CONFIRMATION
                if [[ "$INSTALL_CONFIRMATION" == "y" || "$INSTALL_CONFIRMATION" == "Y" ]]; then
                    sudo zypper install -y unzip
                else
                    echo "Installation of unzip was skipped. Exiting script."
                    exit 1
                fi
                ;;
        esac
    fi

    # Now, unzip the file after checking or installing unzip
    unzip /tmp/Linux64.zip -d /tmp/cvt_tool

    # Step 2: Grant execution permissions to the executable
    echo "🔎 Granting execution permissions to msp_port_checker_packed.exe..."
    chmod +x /tmp/cvt_tool/msp_port_checker_packed.exe

    # Step 3: Prompt for user input
    read -p "Enter login (--your-acronis-user--): " LOGIN
    HOST=cloudbackup.datacomm.co.id

    # Step 4: Run the tool and save output to a log file
    HOSTNAME=$(hostname)
    DATE=$(date +'%Y-%m-%d')
    LOG_FILE="/tmp/cvt_${HOSTNAME}_${DATE}.log"

    log_with_timestamp() {
        while IFS= read -r line; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - $line"
        done
    }
    
    echo "🏃 Running the CVT tool..."
    cd /tmp/cvt_tool/
    sudo ./msp_port_checker_packed.exe -u="$LOGIN" -h="$HOST" | tee "$LOG_FILE"
    
    echo "✅ The CVT tool has finished running. Output saved to: $LOG_FILE"
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

install_agent() {
echo "🔹 Start the agent installation process..."
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
}

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

    HOSTNAME=$(hostname)
    DATE=$(date +'%Y-%m-%d')
    LOG_FILE="/tmp/acropsh_${HOSTNAME}_${DATE}.log"

    # Step 5: Execute the acropsh tool and log the output with timestamps
    echo "Running the acropsh tool..."
    
    # Function to add timestamps to logs
    log_with_timestamp() {
        while IFS= read -r line; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - $line"
        done
    }

    # Run the acropsh tool, adding timestamps to logs
    OUTPUT=$(cd /tmp/acronis_script/linux_installation_healthcheck/ && sudo acropsh main.py | log_with_timestamp >> "$LOG_FILE" 2>&1)

    # Step 6: Monitor for the generated HTML file in the log and check its existence
    GENERATED_HTML_FILE=""
    while true; do
        GENERATED_HTML_FILE=$(tail -n 1 "$LOG_FILE" | grep -oP 'HTML report saved to \K.*\.html' | head -n 1)
        
        if [ -n "$GENERATED_HTML_FILE" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Generated HTML file: $GENERATED_HTML_FILE"
            break
        fi
        
        sleep 1  # Wait 1 second before checking again
    done

    # Step 7: Update file permissions
    if [ -n "$GENERATED_HTML_FILE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Changing permissions of the generated HTML file to rw--r--r-- (644)..."
        chmod 644 "$GENERATED_HTML_FILE"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Permissions updated successfully."
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ No HTML file generated. Skipping permission update."
    fi
}

# Banner and menu
display_menu() {
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║            ACRONIS CYBER PROTECT SCRIPT               ║"
    echo "║-------------------------------------------------------║"
    echo "║ Docs : https://github.com/ipunkpras/acronis-installer ║"
    echo "║ Org. : Dcloud @PT. Datacomm Diangraha🏢               ║"
    echo "║---- v1.0 |     🌐 ipunkpras.my.id   | JKT,ID 2025 ----║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
    echo "Choose Action:"
    echo "[1] Install Acronis Agent"
    echo "[2] Uninstall Acronis Agent"
    echo "[3] Check Acronis Services"
    echo "[4] Run acropsh Tool"
    echo "[5] Run CVT Tool"
    echo "[0] Cancel / Exit"
    read -rp "Enter the options (0/1/2/3/4/5): " ACTION
}

# Main Menu Loop
while true; do
    display_menu
    
    case "$ACTION" in
        1)
            install_agent
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
        5)
            run_cvt_tool
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
