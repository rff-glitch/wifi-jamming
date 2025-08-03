# 💥 blast.sh 💥

## Global WiFi Deauth Attack Tool

`blast.sh` is a powerful Bash script designed for educational purposes to demonstrate and perform Wi-Fi deauthentication attacks. It combines various attack modes, including targeting a single Access Point (AP), launching a global attack against all detected networks, and specifically targeting individual client devices connected to an AP.

**Disclaimer**: This tool is for educational use only. The author is not responsible for any misuse or damage caused by this script. Use it responsibly and only on networks you have explicit permission to test.

## 🚀 Features

*   **Root Access Check**: Ensures the script is run with necessary privileges.
*   **Dependency Installation**: Automatically detects your Linux distribution's package manager (apt, pacman, dnf, yum, zypper) and installs required tools like `aircrack-ng`, `macchanger`, and `xterm`.
*   **Command Verification**: Checks for the presence of essential commands (`airmon-ng`, `airodump-ng`, `aireplay-ng`, `xterm`, `iwconfig`, `macchanger`).
*   **Interactive Interface Selection**: Allows the user to choose their wireless interface for the attack.
*   **Monitor Mode Activation**: Automatically puts the selected wireless interface into monitor mode.
*   **Network Scanning**: Scans and lists available Wi-Fi networks (Access Points) with their BSSID, Channel, and ESSID.
*   **Client Scanning**: For targeted attacks, it can scan and list connected clients on a selected Access Point, including their MAC address and estimated vendor.
*   **Multiple Attack Modes**:
    *   **Global Attack**: Deauthenticates all detected networks.
    *   **Single Network Attack**: Targets a specific Access Point.
    *   **Client-Specific Attack**: Targets one or more specific client devices connected to a chosen AP.
*   **Real-time Attack Animation**: Provides visual feedback during the attack.
*   **Automatic Cleanup**: Restores the wireless interface to managed mode and restarts network services upon script exit or interruption (Ctrl+C).

## 🛠️ Prerequisites

*   A Linux-based operating system.
*   A compatible wireless adapter that supports monitor mode and packet injection.
*   Root privileges to run the script.

## 📦 Installation

1.  **Clone the repository (or download the script):**

    ```bash
    git clone https://github.com/rff-glitch/wifi-jamming
    cd wifi-jamming/
    ```

2.  **Make the script executable:**

    ```bash
    chmod +x blast.sh
    ```

3.  **Copy the script to your system's PATH (optional, but recommended for easy access):**

    The script automatically attempts to copy itself to `/usr/bin/blast` during its initial run.

    ```bash
    sudo cp ./blast.sh /usr/bin/blast
    ```

## 🚀 Usage

1.  **Run the script as root:**

    ```bash
    sudo ./blast.sh
    # OR if copied to /usr/bin
    sudo blast
    ```

2.  **Follow the on-screen prompts:**
    *   The script will first check for and install any missing dependencies.
    *   It will then display available wireless interfaces for you to select.
    *   After selecting an interface, it will enable monitor mode.
    *   A network scan will commence, displaying detected Access Points.
    *   You will then be prompted to choose an attack mode:
        *   `[0] Global Attack`: Targets all detected networks.
        *   `[1] Single Network Attack`: Allows you to select one specific AP from the list.
        *   `[2] Client-Specific Attack`: Requires you to select an AP, then scans for and allows you to choose specific clients to deauthenticate.
    *   Press `ENTER` to start the chosen attack.
    *   Press `ENTER` again (or `Ctrl+C`) to stop the attack and clean up.

## 🧹 Cleanup

The script includes a `cleanup` function that is automatically triggered upon exit or when `Ctrl+C` is pressed. This function will:

*   Stop all `aireplay-ng` and `xterm` processes launched by the script.
*   Restore your wireless interface from monitor mode back to managed mode.
*   Restart `NetworkManager` and `wpa_supplicant` services to re-establish network connectivity.
*   Remove temporary scan files.

## ⚠️ Important Notes

*   **Ethical Hacking**: This tool should only be used for legitimate security testing and educational purposes. Always obtain proper authorization before performing any attacks on a network.
*   **Legal Implications**: Unauthorized deauthentication attacks can be illegal and may lead to severe penalties.
*   **Stability**: While efforts are made to ensure stability, network conditions and hardware can vary.
*   **Troubleshooting**: If you encounter issues, ensure your wireless adapter supports monitor mode and injection, and that all dependencies are correctly installed.

## 🤝 Contributing

Contributions are welcome! If you have suggestions for improvements, bug fixes, or new features, please feel free to open an issue or submit a pull request.

## 📄 License

This project is open-source and available under the [MIT License](LICENSE) 

##  Contact Me

For questions or support, you can reach out to the author:

*   **Raef (rff-glitch)**

---
