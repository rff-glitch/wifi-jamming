# 📡 WiFi Jamming Tool

> Automated multi-target deauthentication attack system using `aircrack-ng`  
> **Author**: Raef (`rff-glitch`)  
> **License**: MIT  
> **Use responsibly. For authorized testing only.**

---

## ⚠️ Legal Disclaimer

This tool is intended **strictly for educational purposes** and **authorized penetration testing**.  
**DO NOT** use it on any network you do not own or have explicit permission to audit.

Misuse may violate laws and result in severe consequences.  
You are **solely responsible** for your actions.

---

## 🎯 Features

- 🔎 Auto-detects and lists wireless interfaces  
- 📡 Switches interfaces to monitor mode  
- 📶 Scans and displays nearby access points (APs)  
- 🚀 Simultaneously launches multiple `aireplay-ng` deauth attacks  
- 💻 Dynamic terminal UX with scanning animations and `xterm` attack windows  
- 🧠 Zenity GUI version available for ease of use

---

## 🧰 Requirements

Tested on Debian-based systems (e.g., Kali Linux, Parrot OS).

Install required packages:

```bash
sudo apt update
sudo apt install aircrack-ng xterm
```

Optional (for GUI version):

```bash
sudo apt install zenity
```

---

## 🔧 Installation

Clone the repository and make scripts executable:

```bash
git clone https://github.com/rff-glitch/wifi-jamming.git
cd wifi-jamming
chmod +x blast.sh GUI-blast.sh
```

---

## 🚀 Usage

### ▶️ CLI Version

```bash
sudo ./blast.sh
```

### 🖱️ GUI Version (Zenity)

If you prefer graphical interaction:

```bash
sudo ./GUI-blast.sh
```

The GUI will prompt you to:
- Select a wireless interface
- Wait for AP scanning
- Choose a target network
- Confirm attack launch via `xterm`

---

## 🧠 How It Works

1. **Interface Selection** — chooses wireless card and enables monitor mode  
2. **Scanning** — uses `airodump-ng` to detect nearby APs  
3. **Attack Selection** — user selects target AP(s)  
4. **Execution** — launches `aireplay-ng` in `xterm` windows for each target  
5. **Cleanup** — tool stops monitor mode and resets interface on exit or interruption

---

## 📂 File Structure

| File             | Description                                  |
|------------------|----------------------------------------------|
| `blast.sh`       | Terminal-based interactive attack script     |
| `GUI-blast.sh`   | Zenity GUI-based interface                   |
| `LICENSE`        | MIT License                                  |

---

## 📸 Screenshots

> *(Add screenshots or gifs showing AP selection and `xterm` blast windows)*

---

## ✅ Tested On

The tool has been tested on:

- ✅ Kali Linux 2023.x (rolling)
- ✅ Parrot OS 6.x
- ✅ Ubuntu 22.04 LTS with `aircrack-ng` installed manually
- ✅ Custom Refracta-based distros

---

## 🧪 Future Improvements

- ✨ Logging system for audit trails  
- 🔐 Runtime encryption & anti-debug protections  
- 📁 AP filtering based on MAC/vendor  
- 🔧 Configurable delay and deauth count per target

---

## 👤 Author

**Raef** — aka `rff-glitch`  
🛠 Cybersecurity Enthusiast • Linux Power User • Scripting Addict

GitHub Profile: [github.com/rff-glitch](https://github.com/rff-glitch)

Contact for collaboration or bug reports through GitHub issues.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).  
Use it responsibly. Abuse leads to legal consequences.

---

## 🤝 Contributing

Pull requests are welcome.  
To suggest a new feature or report a bug, open an issue with full details.

---

## ⭐️ Give It a Star

If this tool helped you, please consider giving the repository a ⭐ on GitHub.

---
