#!/bin/bash

# --- Install Script for AllStarLink Internet Monitor ---
# Professional, friendly, and just a little bit hammy.

echo "Welcome to the AllStarLink Internet Monitor Installer!"
echo

# Prompt for AllStarLink node number
read -p "Please enter your AllStarLink node number: " NODE_NUMBER

# Download audio files
SOUND_DIR="/usr/share/asterisk/sounds/custom"
mkdir -p "$SOUND_DIR"
cd "$SOUND_DIR" || exit 1

echo "Downloading audio prompts..."
wget -q -O internet-no.ul http://198.58.124.150/kd5fmu/internet-no.ul || { echo "Failed to download internet-no.ul"; exit 1; }
wget -q -O internet-yes.ul http://198.58.124.150/kd5fmu/internet-yes.ul || { echo "Failed to download internet-yes.ul"; exit 1; }
echo "Audio files installed to $SOUND_DIR"
echo

# Create the monitor script
MONITOR_SCRIPT="/usr/local/bin/internet_monitor.sh"
cat > "$MONITOR_SCRIPT" << EOF
#!/bin/bash

NODE=$NODE_NUMBER
CHECK_INTERVAL=60
NO_CONNECTION_FILE="$SOUND_DIR/internet-no"
YES_CONNECTION_FILE="$SOUND_DIR/internet-yes"
ASTERISK_CLI="/usr/sbin/asterisk"
NETWORK_OK=0

function play_audio {
    # Play audio file over radio via AllStarLink's Asterisk CLI
    \$ASTERISK_CLI -rx "rpt localplay \$NODE \$1"
}

function has_internet {
    ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1
    return \$?
}

function try_reconnect {
    echo "[INFO] Attempting to reconnect network..."
    # Try restarting networking for WiFi or Ethernet
    if [ -x /usr/bin/nmcli ]; then
        # NetworkManager method
        /usr/bin/nmcli networking off
        sleep 3
        /usr/bin/nmcli networking on
    else
        # Fallback for basic systems
        /usr/sbin/ifdown --exclude=lo -a ; sleep 3 ; /usr/sbin/ifup --exclude=lo -a
    fi
}

while true; do
    if has_internet; then
        if [ \$NETWORK_OK -eq 0 ]; then
            play_audio \$YES_CONNECTION_FILE
            echo "[INFO] Internet reconnected. AllStarLink node should be back on the network!"
        fi
        NETWORK_OK=1
    else
        if [ \$NETWORK_OK -eq 1 ]; then
            play_audio \$NO_CONNECTION_FILE
            echo "[WARNING] Internet lost. AllStarLink node is offline!"
        fi
        NETWORK_OK=0
        try_reconnect
    fi
    sleep \$CHECK_INTERVAL
done
EOF

chmod +x "$MONITOR_SCRIPT"
echo "Monitor script created at $MONITOR_SCRIPT"

# Create systemd service
SERVICE_FILE="/etc/systemd/system/internet-monitor.service"
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=AllStarLink Internet Connection Monitor
After=network.target asterisk.service

[Service]
Type=simple
ExecStart=$MONITOR_SCRIPT
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable internet-monitor.service
systemctl restart internet-monitor.service

echo
echo "Installation complete!"
echo "Your AllStarLink node will now check internet connectivity every 60 seconds and play an audio file when connection is lost or restored."
echo "If you ever want to change the node number, just re-run this installer script."
echo
echo "If you hear 'internet-no' on the air, don't panic—you're just out of the digital woods. 73!"
