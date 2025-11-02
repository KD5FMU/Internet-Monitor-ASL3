#!/bin/bash

# --- Install Script for AllStarLink Internet Monitor ---
# The file was created from the mind of Freddie Mac - KD5FMU Ham Radio Crusader
# Professional, friendly, and just a little bit hammy.
# Enhanced with better error handling, logging, and reliability
# Copyright (C) 2025 Jory A. Pratt <geekypenguin@gmail.com>
# Released under the GNU General Public License v3.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
CONFIG_FILE="/etc/internet-monitor.conf"
DEFAULT_CHECK_INTERVAL=180
DEFAULT_PING_HOSTS="1.1.1.1 8.8.8.8 208.67.222.222"

# Logging function (for installer script)
log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # Ensure log directory exists
    mkdir -p "$(dirname /var/log/internet-monitor.log)"
    echo "[$timestamp] [$level] $message" >> /var/log/internet-monitor.log
}

# Enhanced print functions
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
    log_message "INFO" "$1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    log_message "WARN" "$1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_message "ERROR" "$1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to validate node number
validate_node_number() {
    local node_num="$1"
    if [[ ! "$node_num" =~ ^[0-9]+$ ]] || [ "$node_num" -lt 1 ]; then
        print_error "Invalid node number. Please enter a positive integer."
        return 1
    fi
    return 0
}

# Function to get configuration
get_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Prompt for AllStarLink node number with validation
    while true; do
        read -p "Please enter your AllStarLink node number: " NODE_NUMBER
        if validate_node_number "$NODE_NUMBER"; then
            break
        fi
    done
    
    # Prompt for check interval
    read -p "Enter check interval in seconds (default: $DEFAULT_CHECK_INTERVAL): " CHECK_INTERVAL
    CHECK_INTERVAL=${CHECK_INTERVAL:-$DEFAULT_CHECK_INTERVAL}
    
    # Validate check interval
    if [[ ! "$CHECK_INTERVAL" =~ ^[0-9]+$ ]] || [ "$CHECK_INTERVAL" -lt 30 ]; then
        print_warning "Invalid check interval, using default: $DEFAULT_CHECK_INTERVAL"
        CHECK_INTERVAL=$DEFAULT_CHECK_INTERVAL
    fi
}

# Function to create the enhanced monitor script
create_monitor_script() {
    MONITOR_SCRIPT="/usr/local/bin/internet_monitor.sh"
    
    cat > "$MONITOR_SCRIPT" << 'EOF'
#!/bin/bash

# Enhanced Internet Monitor Script for AllStarLink ASL3+
# Copyright (C) 2025 Jory A. Pratt <geekypenguin@gmail.com>
# Released under the GNU General Public License v3.0

# Error handling: exit on error, undefined variables, pipe failures
set -euo pipefail
IFS=$'\n\t'

# Global flag for graceful shutdown
RUNNING=1

# Cleanup function for graceful shutdown
cleanup() {
    RUNNING=0
    print_status "Received shutdown signal, gracefully stopping..."
    exit 0
}

# Set up signal handlers for graceful shutdown
trap cleanup SIGTERM SIGINT

# Validate required commands
check_commands() {
    local missing_commands=()
    
    for cmd in ping systemctl ip date; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        echo "ERROR: Missing required commands: ${missing_commands[*]}" >&2
        exit 1
    fi
}

# Load configuration with validation
CONFIG_FILE="/etc/internet-monitor.conf"
if [ -f "$CONFIG_FILE" ]; then
    # Validate config file before sourcing (basic security check)
    if grep -q "^[^#]*[;&|<>]" "$CONFIG_FILE"; then
        echo "ERROR: Invalid characters in configuration file" >&2
        exit 1
    fi
    # Source config file safely
    set +u
    source "$CONFIG_FILE"
    set -u
fi

# Default values
NODE=${NODE_NUMBER:-12345}
CHECK_INTERVAL=${CHECK_INTERVAL:-180}
PING_HOSTS=${PING_HOSTS:-"1.1.1.1 8.8.8.8 208.67.222.222"}
SOUND_DIR=${SOUND_DIR:-"/usr/share/asterisk/sounds/custom"}
LOG_FILE=${LOG_FILE:-"/var/log/internet-monitor.log"}
ASTERISK_CLI=${ASTERISK_CLI:-"/usr/sbin/asterisk"}
MAX_LOG_SIZE=${MAX_LOG_SIZE:-10485760}  # 10MB default
LOG_RETENTION=${LOG_RETENTION:-5}  # Keep 5 rotated logs
NETWORK_OK=0
LAST_STATUS=""
LAST_RESTART_ATTEMPT=0
RESTART_COOLDOWN=300  # 5 minutes between restart attempts
CONSECUTIVE_FAILURES=0

# Validate configuration values
if ! [[ "$NODE" =~ ^[0-9]+$ ]] || [ "$NODE" -lt 1 ]; then
    echo "ERROR: Invalid NODE_NUMBER: $NODE" >&2
    exit 1
fi

if ! [[ "$CHECK_INTERVAL" =~ ^[0-9]+$ ]] || [ "$CHECK_INTERVAL" -lt 30 ]; then
    echo "ERROR: Invalid CHECK_INTERVAL: $CHECK_INTERVAL (minimum 30 seconds)" >&2
    exit 1
fi

# Check commands at startup
check_commands

# Validate Asterisk CLI path
if [ ! -x "$ASTERISK_CLI" ]; then
    echo "WARNING: Asterisk CLI not found at $ASTERISK_CLI, audio playback will be disabled" >&2
    ASTERISK_CLI=""
fi

# Log rotation function
rotate_log() {
    local log_file="$1"
    if [ ! -f "$log_file" ]; then
        return 0
    fi
    
    local log_size
    log_size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
    
    if [ "$log_size" -gt "$MAX_LOG_SIZE" ]; then
        # Rotate logs
        for i in $(seq $((LOG_RETENTION - 1)) -1 1); do
            if [ -f "${log_file}.${i}" ]; then
                mv "${log_file}.${i}" "${log_file}.$((i + 1))"
            fi
        done
        mv "$log_file" "${log_file}.1"
        touch "$log_file"
    fi
}

# Logging function with rotation
log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Rotate log if needed
    rotate_log "$LOG_FILE"
    
    # Ensure log file directory exists
    mkdir -p "$(dirname "$LOG_FILE")"
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Enhanced print functions
print_status() {
    echo "[INFO] $1"
    log_message "INFO" "$1"
}

print_warning() {
    echo "[WARN] $1"
    log_message "WARN" "$1"
}

print_error() {
    echo "[ERROR] $1"
    log_message "ERROR" "$1"
}

function play_audio {
    local audio_file="$1"
    local audio_path
    
    # Handle both cases: with and without .ul extension
    if [[ "$audio_file" == *.ul ]]; then
        audio_path="$audio_file"
    else
        audio_path="${audio_file}.ul"
    fi
    
    # Check if file exists with or without path
    if [ -f "$audio_path" ]; then
        local full_path="$audio_path"
    elif [ -f "${SOUND_DIR}/${audio_path}" ]; then
        local full_path="${SOUND_DIR}/${audio_path}"
    elif [ -f "${audio_file}.ul" ]; then
        local full_path="${audio_file}.ul"
    elif [ -f "${SOUND_DIR}/${audio_file}.ul" ]; then
        local full_path="${SOUND_DIR}/${audio_file}.ul"
    else
        print_warning "Audio file not found: $audio_path (checked $audio_path, ${SOUND_DIR}/${audio_path})"
        return 1
    fi
    
    # Play audio if Asterisk CLI is available
    if [ -n "$ASTERISK_CLI" ] && [ -x "$ASTERISK_CLI" ]; then
        # Extract just the filename without extension for Asterisk
        local filename
        filename=$(basename "$full_path" .ul)
        "$ASTERISK_CLI" -rx "rpt localplay $NODE $filename" >/dev/null 2>&1 || true
        print_status "Played audio: $filename"
    else
        print_warning "Asterisk CLI not available, skipping audio playback"
    fi
}

function has_internet {
    local hosts="$1"
    local timeout="${2:-5}"
    local host
    local old_ifs
    
    # Convert space-separated hosts to array for safe iteration
    # This handles hosts that might contain spaces (though IPs shouldn't)
    local hosts_array
    old_ifs="$IFS"
    IFS=' ' read -ra hosts_array <<< "$hosts"
    IFS="$old_ifs"
    
    # Ping with timeout - try GNU/Linux syntax first, then alternatives
    for host in "${hosts_array[@]}"; do
        # Skip empty entries
        [ -z "$host" ] && continue
        
        # GNU/Linux ping: -W timeout (wait timeout seconds for response)
        # This should work on most Linux systems
        if ping -c 1 -W "$timeout" "$host" >/dev/null 2>&1; then
            return 0
        # Fallback: Some systems may use different syntax
        # Try without timeout flag (will use default timeout)
        elif ping -c 1 "$host" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

function test_dns {
    # Test DNS resolution using multiple methods for compatibility
    # Method 1: getent (most universal, available on most systems)
    if getent hosts google.com >/dev/null 2>&1; then
        return 0
    fi
    # Method 2: host command (common alternative)
    if command -v host >/dev/null 2>&1 && host google.com >/dev/null 2>&1; then
        return 0
    fi
    # Method 3: nslookup (fallback, may not be available)
    if command -v nslookup >/dev/null 2>&1 && nslookup google.com >/dev/null 2>&1; then
        return 0
    fi
    # Method 4: dig (last resort)
    if command -v dig >/dev/null 2>&1 && dig +short google.com >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

function comprehensive_connectivity_test {
    # Test multiple connectivity aspects
    local ping_hosts="${PING_HOSTS:-"1.1.1.1 8.8.8.8 208.67.222.222"}"
    
    # Test basic ping (properly quoted)
    if has_internet "$ping_hosts" 3; then
        # Test DNS resolution
        if test_dns; then
            return 0
        else
            print_warning "Ping works but DNS resolution failed"
            return 1
        fi
    fi
    return 1
}

function detect_network_manager {
    # Detect which network manager is running
    if systemctl is-active --quiet NetworkManager; then
        echo "NetworkManager"
    elif systemctl is-active --quiet systemd-networkd; then
        echo "systemd-networkd"
    elif command -v netplan >/dev/null 2>&1; then
        echo "netplan"
    else
        echo "unknown"
    fi
}

function verify_networkmanager_status {
    # Verify NetworkManager is actually running and functional
    if ! systemctl is-active --quiet NetworkManager; then
        print_error "NetworkManager is not active"
        return 1
    fi
    
    # Check if NetworkManager is in a good state
    if systemctl is-failed --quiet NetworkManager; then
        print_error "NetworkManager is in failed state"
        return 1
    fi
    
    # Give it a moment to settle
    sleep 2
    
    # Check if any network interfaces are up
    if ip link show | grep -q "state UP"; then
        print_status "Network interfaces are up"
        return 0
    else
        print_warning "No network interfaces are up yet"
        return 1
    fi
}

function restart_networkmanager {
    local nm_type
    nm_type=$(detect_network_manager)
    
    print_status "Detected network manager: $nm_type"
    print_status "Attempting NetworkManager restart via systemctl..."
    
    # Check if NetworkManager is available
    if [ "$nm_type" != "NetworkManager" ]; then
        print_error "NetworkManager is not the active network manager (detected: $nm_type)"
        return 1
    fi
    
    # Stop NetworkManager
    if systemctl stop NetworkManager 2>&1 | tee -a "$LOG_FILE"; then
        print_status "NetworkManager stopped successfully"
        sleep 5
        
        # Start NetworkManager
        if systemctl start NetworkManager 2>&1 | tee -a "$LOG_FILE"; then
            print_status "NetworkManager start command issued"
            sleep 10
            
            # Verify it actually started and is functional
            if verify_networkmanager_status; then
                print_status "NetworkManager restarted and verified successfully"
                return 0
            else
                print_error "NetworkManager started but is not functional"
                # Try to get status for debugging
                systemctl status NetworkManager --no-pager | head -20 >> "$LOG_FILE"
                return 1
            fi
        else
            print_error "Failed to start NetworkManager"
            systemctl status NetworkManager --no-pager | head -20 >> "$LOG_FILE"
            return 1
        fi
    else
        print_error "Failed to stop NetworkManager"
        systemctl status NetworkManager --no-pager | head -20 >> "$LOG_FILE"
        return 1
    fi
}

function try_reconnect {
    local current_time=$(date +%s)
    local time_since_last_restart=$((current_time - LAST_RESTART_ATTEMPT))
    
    # Check if we're in cooldown period
    if [ "$LAST_RESTART_ATTEMPT" -ne 0 ] && [ "$time_since_last_restart" -lt "$RESTART_COOLDOWN" ]; then
        local time_remaining=$((RESTART_COOLDOWN - time_since_last_restart))
        print_warning "In cooldown period. Next restart attempt in $time_remaining seconds"
        return 1
    fi
    
    print_warning "Attempting to reconnect network... (Attempt after $time_since_last_restart seconds)"
    LAST_RESTART_ATTEMPT=$current_time
    
    # Use proper systemctl commands for NetworkManager
    if restart_networkmanager; then
        print_status "Network reconnection successful"
        CONSECUTIVE_FAILURES=0
        return 0
    else
        print_error "Network reconnection failed"
        CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
        
        # Implement exponential backoff
        if [ "$CONSECUTIVE_FAILURES" -ge 3 ]; then
            RESTART_COOLDOWN=$((RESTART_COOLDOWN * 2))
            if [ "$RESTART_COOLDOWN" -gt 3600 ]; then
                RESTART_COOLDOWN=3600  # Cap at 1 hour
            fi
            print_warning "Increased cooldown to $RESTART_COOLDOWN seconds after $CONSECUTIVE_FAILURES consecutive failures"
        fi
        
        return 1
    fi
}

# Main monitoring loop
print_status "Internet monitor started for node $NODE"
print_status "Check interval: $CHECK_INTERVAL seconds"
print_status "Ping hosts: $PING_HOSTS"

# Main monitoring loop with graceful shutdown support
while [ "$RUNNING" -eq 1 ]; do
    # Temporarily disable error exit for connectivity test (may fail normally)
    set +e
    if comprehensive_connectivity_test; then
        set -e
        if [ "$NETWORK_OK" -eq 0 ]; then
            play_audio "${SOUND_DIR}/internet-yes"
            print_status "Internet reconnected. AllStarLink node should be back on the network!"
            LAST_STATUS="connected"
            # Reset cooldown and failure counters on successful connection
            CONSECUTIVE_FAILURES=0
            RESTART_COOLDOWN=300
        fi
        NETWORK_OK=1
    else
        set -e
        if [ "$NETWORK_OK" -eq 1 ]; then
            play_audio "${SOUND_DIR}/internet-no"
            print_warning "Internet lost. AllStarLink node is offline!"
            LAST_STATUS="disconnected"
        fi
        NETWORK_OK=0
        # Disable error exit for reconnect attempt (may fail normally)
        set +e
        try_reconnect
        set -e
    fi
    
    # Check RUNNING flag before sleep (allows immediate exit on signal)
    if [ "$RUNNING" -eq 1 ]; then
        sleep "$CHECK_INTERVAL"
    fi
done

print_status "Internet monitor stopped gracefully"
EOF

    chmod +x "$MONITOR_SCRIPT"
    print_status "Enhanced monitor script created at $MONITOR_SCRIPT"
}

# Function to create configuration file
create_config_file() {
    # Find Asterisk CLI path if it exists
    local asterisk_path=""
    if [ -x "/usr/sbin/asterisk" ]; then
        asterisk_path="/usr/sbin/asterisk"
    elif command -v asterisk >/dev/null 2>&1; then
        asterisk_path=$(command -v asterisk)
    fi
    
    cat > "$CONFIG_FILE" << EOF
# Internet Monitor Configuration
# Copyright (C) 2025 Jory A. Pratt <geekypenguin@gmail.com>
# DO NOT ADD COMMANDS OR SPECIAL CHARACTERS - This file is sourced directly
NODE_NUMBER=$NODE_NUMBER
CHECK_INTERVAL=$CHECK_INTERVAL
PING_HOSTS="$DEFAULT_PING_HOSTS"
SOUND_DIR="/usr/share/asterisk/sounds/custom"
LOG_FILE="/var/log/internet-monitor.log"
ASTERISK_CLI="${asterisk_path:-/usr/sbin/asterisk}"
MAX_LOG_SIZE=10485760
LOG_RETENTION=5
EOF
    
    chmod 644 "$CONFIG_FILE"
    print_status "Configuration saved to $CONFIG_FILE"
}

# Function to download audio files with better error handling
download_audio_files() {
    print_header "Downloading Audio Files"
    SOUND_DIR="/usr/share/asterisk/sounds/custom"
    mkdir -p "$SOUND_DIR"
    cd "$SOUND_DIR" || {
        print_error "Failed to create sound directory"
        exit 1
    }
    
    local audio_files=(
        "https://raw.githubusercontent.com/KD5FMU/Internet-Monitor-ASL3/main/internet-no.ul|internet-no.ul"
        "https://raw.githubusercontent.com/KD5FMU/Internet-Monitor-ASL3/main/internet-yes.ul|internet-yes.ul"
    )
    
    for file_info in "${audio_files[@]}"; do
        local url="${file_info%|*}"
        local filename="${file_info#*|}"
        
        if ! wget -q -O "$filename" "$url"; then
            print_error "Failed to download $filename"
            exit 1
        fi
        print_status "Downloaded $filename"
    done
}

# Function to install service
install_service() {
    SERVICE_FILE="/etc/systemd/system/internet-monitor.service"
    
    # Create systemd service with better configuration
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=AllStarLink Internet Connection Monitor
After=network.target asterisk.service NetworkManager.service
Wants=network.target

[Service]
Type=simple
ExecStart=$MONITOR_SCRIPT
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
User=root
Group=root

# Security settings (relaxed to allow NetworkManager control)
# NoNewPrivileges=true - Disabled to allow systemctl commands
# ProtectSystem=strict - Disabled to allow network management
ProtectHome=true
ReadWritePaths=/var/log /etc/asterisk /run/dbus /var/run/dbus /run/systemd

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable internet-monitor.service
    
    if systemctl is-active --quiet internet-monitor.service; then
        systemctl restart internet-monitor.service
    else
        systemctl start internet-monitor.service
    fi
    
    print_status "Service installed and started"
}

# Main installation function
main() {
    print_header "AllStarLink Internet Monitor Installer"
    
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
    
    # Get configuration
    get_config
    
    # Download audio files
    download_audio_files
    
    # Create monitor script with enhanced functionality
    create_monitor_script
    
    # Create configuration file
    create_config_file
    
    # Install service
    install_service
    
    print_header "Installation Complete"
    print_status "Internet monitor configured for node $NODE_NUMBER"
    print_status "Check interval: $CHECK_INTERVAL seconds"
    print_status "Log file: /var/log/internet-monitor.log"
    print_status "Configuration: $CONFIG_FILE"
    echo
    echo "If you hear 'internet-disconnected' on the air, don't panic—you're just out of the digital woods. 73!"
}

# Run main function
main "$@"
