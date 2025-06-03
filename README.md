
# 🚨 WiFi DEAUTH BLASTER 🔥

A powerful **AP-only focused deauthentication** bash script designed for rapid wireless disruption using `aircrack-ng` tools. This script automates the scanning and blasting of all nearby WiFi networks in range using aggressive deauth attacks. ⚔️

> ⚠️ **DISCLAIMER**  
> This tool is intended **strictly for educational and authorized security testing** purposes only.  
> Unauthorized use against networks you do not own or have permission to test is **illegal** and unethical.

---

## ✨ Features

- 📡 Auto-detects wireless interfaces
- 🧠 Automatically enters monitor mode
- 🛰️ Scans and lists visible APs
- 💣 Launches multiple parallel deauth attacks per target
- 🖥️ Uses `xterm` windows for live attack visuals
- 🎬 Animated terminal output and scan countdown

---

## 🧰 Requirements

Make sure you're on a **Debian-based Linux** system with root access and run:

```bash
sudo apt update && sudo apt install aircrack-ng xterm
```

---

## 🚀 Usage

1. **Clone the repository** and give script execution permission:

```bash
git clone https://github.com/rff-glitch/wifi-jamming.git
cd wifi-jamming
chmod +x blast.sh
```

2. **Run the script with root privileges**:

```bash
sudo ./blast.sh
```

3. Follow on-screen instructions to:
   - Select a wireless interface
   - Wait for scanning to finish
   - View and confirm targets
   - Begin full-scale deauthentication attacks ⚔️

---

## 📷 Preview

```
🧠 Interface Selection
📡 Scanning for targets...
🎯 Displaying APs
💣 Launching attacks in xterm
🔥 LIVE BLASTING in progress!
```

---

## 📌 Notes

- The script opens **multiple `xterm` windows** per target. Make sure your system supports GUI windows.
- Automatically cleans up and restores network settings upon `CTRL+C`.
- Logs are not stored; attacks are transient and run in memory.

---

## 🛑 STOPPING ATTACKS

Simply press `CTRL+C` anytime during the attack phase to **terminate all sessions** and **restore your network interface** to managed mode.

---

## ⚙️ Tested On

- ✅ Kali Linux
- ✅ Parrot OS
- ✅ Ubuntu with aircrack-ng installed

---

## 🙋‍♂️ Author

Made with 💥 by **RAEF**  
Feel free to contribute, fork, or report bugs 🐛!

---

## 🧨 License

This project is released under the [MIT License](LICENSE).

> 🛡️ Use responsibly. You are solely accountable for how you use this tool.

