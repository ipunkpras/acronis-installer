#!/bin/bash
# v1.1 Install and Uninstall Acronis Cyber Protect Agent - Datacomm Cloud Backup

# Log file for cleanup process
LOG_CLEANUP="/tmp/cleanup_$(date +'%Y-%m-%d').log"

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

# Clean up temporary files and folders
cleanup() {
    echo "🧹 Cleaning up temporary files..."
    echo "Cleanup started at $(date)" > "$LOG_CLEANUP"

    # Define temporary folders and files to clean up
    TEMP_FILES=(
        "/tmp/Linux64.zip"
        "/tmp/cvt_tool"
        "/tmp/acronis_script.zip"
        "/tmp/acronis_script"
        "/tmp/cvt_*.log"
        "/tmp/acropsh_*.log"
    )

    # Delete each temporary file/folder
    for file in "${TEMP_FILES[@]}"; do
        if [ -e "$file" ]; then
            echo "$(date +'%Y-%m-%d %H:%M:%S') - Deleting: $file" | tee -a "$LOG_CLEANUP"
            rm -rf "$file"
            if [ $? -eq 0 ]; then
                echo "$(date +'%Y-%m-%d %H:%M:%S') - Successfully deleted: $file" | tee -a "$LOG_CLEANUP"
            else
                echo "$(date +'%Y-%m-%d %H:%M:%S') - Failed to delete: $file" | tee -a "$LOG_CLEANUP"
            fi
        else
            echo "$(date +'%Y-%m-%d %H:%M:%S') - File/Folder not found: $file" | tee -a "$LOG_CLEANUP"
        fi
    done

    echo "✅ Cleanup completed." | tee -a "$LOG_CLEANUP"
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

# Check if unzip is installed, if not prompt to install
check_and_install_unzip() {
    if ! command -v unzip &> /dev/null; then
        echo "❌ unzip is not installed."
        read -p "Do you want to install unzip? (y/n): " INSTALL_CONFIRMATION
        if [[ "$INSTALL_CONFIRMATION" == "y" || "$INSTALL_CONFIRMATION" == "Y" ]]; then
            # Detect package manager
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y unzip
            elif command -v yum &> /dev/null; then
                sudo yum install -y unzip
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y unzip
            elif command -v zypper &> /dev/null; then
                sudo zypper install -y unzip
            else
                echo "❌ Unknown package manager. Unable to install unzip."
                exit 1
            fi
        else
            echo "❌ Unable to continue without unzip. Exiting script."
            exit 1
        fi
    fi
}

# CVT Tool Function
run_cvt_tool() {
    echo "🔹 Running CVT Tool..."

    # Step 1: Download the Linux Connection Verification Tool (64bit)
    echo "🔎 Downloading the Linux Connection Verification Tool..."
    wget https://dl.acronis.com/u/support/KB/Linux64.zip -O /tmp/Linux64.zip

    # Check if unzip is available and install if necessary
    check_and_install_unzip

    # Unpack the downloaded file using unzip (since it's a .zip file)
    echo "🔎 Unpacking the downloaded ZIP file..."
    unzip /tmp/Linux64.zip -d /tmp/cvt_tool

    # Step 2: Grant execution permissions to the executable
    echo "🔎 Granting execution permissions to msp_port_checker_packed.exe..."
    chmod u+w /tmp/cvt_tool
    chmod +x /tmp/cvt_tool/msp_port_checker_packed.exe

    # Step 3: Prompt for user input
    read -p "Enter login (--your-acronis-user--): " LOGIN
    HOST=cloudbackup.datacomm.co.id

    # Step 4: Run the tool and save output to a log file
    HOSTNAME=$(hostname)
    DATE=$(date +'%Y-%m-%d')
    LOG_FILE="/tmp/cvt_${HOSTNAME}_${DATE}.log"

    echo "🏃 Running the CVT tool..."
    cd /tmp/cvt_tool/
    sudo ./msp_port_checker_packed.exe -u="$LOGIN" -h="$HOST" | tee "$LOG_FILE"
    
    echo "✅ The CVT tool has finished running. Output saved to: $LOG_FILE"
    sudo chmod o-w /tmp/cvt_tool
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

    # Fetch the available versions from the URL
    echo "🔎 Fetching available versions from the server..."
    available_versions=$(wget -q -O - "https://cloudbackup.datacomm.co.id/download/u/baas/4.0/" | \
        grep -oP 'href="\K[0-9]+\.[0-9]+\.[0-9]+/' | \
        sed 's/\/$//')

    if [[ -z "$available_versions" ]]; then
        echo "❌ No available versions found."
        exit 1
    fi

    echo "Available versions:"
    echo "$available_versions"
    
    # Prompt the user to choose a version from the available list
    read -rp "Enter agent version Acronis (available versions listed above): " VERSION

    # Validate the version input
    if ! echo "$available_versions" | grep -q "$VERSION"; then
        echo "❌ Invalid version selected. Please choose from the available versions."
        exit 1
    fi

    read -rp "Please input the Registration Token: " REGISTRATION_TOKEN
    read -rp "Enter path temporary folder (default: ~/acronis-installer): " TMP_DIR

    # === Validation token ===
    if [[ -z "$REGISTRATION_TOKEN" ]]; then
        echo "❌ Tokens cannot be empty."
        exit 1
    fi

    # if the folder is empty, set default.
    if [[ -z "$TMP_DIR" ]]; then
        TMP_DIR="~/acronis-installer"
    fi

    # Set the Acronis URL and installer path based on the selected version
    ACRONIS_URL="https://cloudbackup.datacomm.co.id/download/u/baas/4.0/$VERSION/$INSTALLER_NAME"
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

    # Check if unzip is available and install if necessary
    check_and_install_unzip
    
    # Step 4: Unpack and run the tool
    unzip /tmp/acronis_script.zip -d /tmp/acronis_script
    OUTPUT=$(cd /tmp/acronis_script/linux_installation_healthcheck/ && sudo python3 main.py)
    
    # Save output to log
    LOG_FILE="/tmp/acropsh_${HOSTNAME}_$(date +'%Y-%m-%d').log"
    echo "$OUTPUT" > "$LOG_FILE"
    
    # Step 5: Monitor for generated HTML file in the log and change its permissions
    GENERATED_HTML_FILE=$(tail -n 1 "$LOG_FILE" | grep -oP 'HTML report saved to \K.*\.html')
    if [ -n "$GENERATED_HTML_FILE" ]; then
        echo "Generated HTML report: $GENERATED_HTML_FILE"
        chmod 644 "$GENERATED_HTML_FILE"
    fi
}

# Banner and menu
display_menu() {
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║            ACRONIS CYBER PROTECT SCRIPT               ║"
    echo "║-------------------------------------------------------║"
    echo "║ Docs : https://github.com/ipunkpras/acronis-installer ║"
    echo "║ Org. : Dcloud @PT. Datacomm Diangraha🏢               ║"
    echo "║---- v1.1 |     🌐 dcloud.co.id      | JKT,ID 2025 ----║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
    echo "Choose Action:"
    echo "[1] Install Acronis Agent"
    echo "[2] Uninstall Acronis Agent"
    echo "[3] Check Acronis Services"
    echo "[4] Run acropsh Tool"
    echo "[5] Run CVT Tool"
    echo "[6] Cleanup Temporary Files"
    echo "[0] Cancel / Exit"
    read -rp "Enter the options (0/1/2/3/4/5/6): " ACTION
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
        6)
            cleanup
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
