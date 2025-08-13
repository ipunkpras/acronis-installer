# Acronis Cyber Protect Agent Installation Script

This script automates the installation, uninstallation, and service checking of the **Acronis Cyber Protect Agent** for Datacomm Cloud Backup. The script supports both Linux systems and provides a menu for the user to select the desired action.

## Features
- Install the Acronis Cyber Protect Agent
- Uninstall the Acronis Cyber Protect Agent
- Check the status of Acronis services
- Create a temporary directory for installation and handle the installer
- Customizable installation version and token

## Requirements
- **Root access**: The script must be run with root privileges to install/uninstall the Acronis agent.
- **Curl**: For downloading the installer.
- **Systemd**: To check the Acronis service status.
  
## Installation

1. **Download the script** or create a new file and paste the script content into it:
   
   ```bash
   nano installer_acronis.sh

2. **Make the script executable**
   
   ```bash
   chmod +x installer_acronis.sh
   
3. **Run the script**
   
   ```bash
   sudo ./installer_acronis.sh

## Usage

When you run the script, you will be presented with the following menu options:

<img width="385" height="253" alt="image" src="https://github.com/user-attachments/assets/62f256bc-cb0a-42e2-a4ce-afdf702db93a" />

## Menu Options

[1] Install Acronis Agent: Start the installation process for the Acronis Cyber Protect Agent.

[2] Uninstall Acronis Agent: Uninstall the currently installed Acronis Cyber Protect Agent.

[3] Check Acronis Services: Check the status of the Acronis services (e.g., aakore, acronis_mms).

[0] Cancel / Exit: Exit the script without making any changes.
