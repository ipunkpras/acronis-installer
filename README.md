# Acronis Cyber Protect Agent Installation Script

This script is designed to manage the installation and uninstallation of **Acronis Cyber Protect Agent** on Linux systems. It also provides functionalities to check the status of required services and run the `acropsh` tool for Datacomm Cloud Backup. The script supports both Linux systems and provides a menu for the user to select the desired action.

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

## Features
- Install or Uninstall Acronis Cyber Protect Agent
- Check the status of Acronis services (`aakore` and `acronis_mms`)
- Install and run the `acropsh` tool
- Python 3 installation if needed

## Requirements
- Root access (sudo privileges)
- Python 3 installed (the script will attempt to install Python 3 if it's missing)
- `acropsh` tool needs to be run only when both `aakore` and `acronis_mms` services are running

## Installation

1. **Clone or Download the Script**:
   - You can download or clone this repository to your server or Linux machine.
   
2. **Make the Script Executable**:
   - Once you've downloaded or cloned the script, navigate to the directory containing the script and run:
     ```bash
     chmod +x installer-acronis.sh
     ```

3. **Run the Script**:
   - To run the script, use the following command:
     ```bash
     sudo ./installer-acronis.sh
     ```

   - The script will display a menu with options.

## Menu Options

Once the script is executed, the menu will display the following options:

1. **[1] Install Acronis Agent**:
   - This option starts the installation process of the Acronis Cyber Protect Agent.

2. **[2] Uninstall Acronis Agent**:
   - This option will uninstall the Acronis Cyber Protect Agent if it is already installed.

3. **[3] Check Acronis Services**:
   - This option checks the status of the Acronis services `aakore` and `acronis_mms`. It will display whether each service is running or not.

4. **[4] Run acropsh Tool**:
   - Run the acropsh tool to check the health and status of the Acronis installation.
     
5. **[5] Run CVT Tool**:
   - Runs the Linux Connection Verification Tool (CVT) to ensure proper connection to Acronis Cloud.
  
6. **[0] Cancel / Exit**:
   - This option will exit the script.

## Example Usage

1. **Start the script**:
   ```bash
   sudo ./installer-acronis.sh


## Usage

When you run the script, you will be presented with the following menu options:

<img width="480" height="302" alt="image" src="https://github.com/user-attachments/assets/f5768ae6-2df2-4473-a846-2820d735dead" />


