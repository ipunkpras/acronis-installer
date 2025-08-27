# Acronis Cyber Protect Agent Installation Script

This script is designed to manage the installation and uninstallation of **Acronis Cyber Protect Agent** on Linux systems. It provides functionalities to check the status of required services, install missing dependencies like `unzip`, and run the `acropsh` tool for Datacomm Cloud Backup. The script includes a menu for selecting the desired action and supports version selection for the Acronis agent installation.

## Features
- **Install the Acronis Cyber Protect Agent**: Install the agent on Linux systems by specifying the desired version and providing a registration token.
- **Uninstall the Acronis Cyber Protect Agent**: Uninstall the Acronis agent if it is already installed.
- **Check the status of Acronis services**: Checks if `aakore` and `acronis_mms` services are running and reports their status.
- **Run `acropsh` tool**: Install and run the `acropsh` tool for Datacomm Cloud Backup health checks.
- **Run CVT Tool**: Verifies the connection to Acronis Cloud using the Linux Connection Verification Tool (CVT).
- **Check and install missing dependencies**: Ensures required packages like `unzip` and `python3` are available and installs them if missing.
- **Cleanup temporary files**: Removes downloaded installation files and logs after the process is complete to maintain a clean environment.

## Requirements
- **Root access**: The script must be run with root privileges to install/uninstall the Acronis agent and manage services.
- **Python 3**: The script checks for Python 3 installation, and installs it if not present.
- **`unzip`**: The script checks if `unzip` is installed before extracting `.zip` files. If it's missing, the script will prompt the user to install it.

## Installation

1. **Clone or Download the Script**:
   - Download or clone this repository to your server or Linux machine.

2. **Make the Script Executable**:
   - Navigate to the directory containing the script and run:
     ```bash
     chmod +x installer-acronis.sh
     ```

3. **Run the Script**:
   - To run the script, use the following command:
     ```bash
     sudo ./installer-acronis.sh
     ```

   - The script will display a menu with options to choose from.

## Menu Options

Once the script is executed, the following menu will be displayed:

1. **[1] Install Acronis Agent**:
   - Starts the installation of the Acronis Cyber Protect Agent.
   - You can select the version of the agent to install from a list of available versions.

2. **[2] Uninstall Acronis Agent**:
   - Uninstalls the Acronis Cyber Protect Agent if it is already installed.

3. **[3] Check Acronis Services**:
   - Checks and reports the status of the `aakore` and `acronis_mms` services. It will display whether each service is running or not.

4. **[4] Run acropsh Tool**:
   - Runs the `acropsh` tool to check the health and status of the Acronis installation.
   - This requires Python 3 to be installed, and the script will handle installation if necessary.

5. **[5] Run CVT Tool**:
   - Runs the **Linux Connection Verification Tool (CVT)** to ensure the connection to Acronis Cloud is working properly.
   - The script checks if `unzip` is installed before extracting the `.zip` file for CVT.

6. **[6] Cleanup Temporary Files**:
   - Cleans up temporary files and folders generated during the installation process, such as downloaded installer files and log files.

7. **[0] Cancel / Exit**:
   - Exits the script without performing any actions.

## Example Usage

1. **Start the script**:
   ```bash
   sudo ./installer-acronis.sh

## Notes

- The script checks for the availability of the required unzip and python3 packages. If they are missing, the script will prompt you to install them using the default package manager for your Linux distribution (e.g., apt, yum, dnf, or zypper).

- Temporary files generated during the installation process are cleaned up after the script finishes. You can choose to delete the installer files manually after installation if you prefer.
- 
