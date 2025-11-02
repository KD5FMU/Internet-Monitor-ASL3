#!/bin/bash

# --- Uninstall Script for AllStarLink Internet Monitor ---
# The file was created from the mind of Freddie Mac - KD5FMU Ham Radio Crusader
# Professional, friendly, and just a little bit hammy.
# Enhanced uninstaller with user-friendly prompts
# Copyright (C) 2025 Jory A. Pratt <geekypenguin@gmail.com>
# Released under the GNU General Public License v3.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# File locations
SERVICE_NAME="internet-monitor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
MONITOR_SCRIPT="/usr/local/bin/internet_monitor.sh"
CONFIG_FILE="/etc/internet-monitor.conf"
SOUND_DIR="/usr/share/asterisk/sounds/custom"
LOG_FILE="/var/log/internet-monitor.log"

# Print functions
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Stop and disable service
stop_service() {
    print_header "Stopping Service"
    
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        print_status "Stopping ${SERVICE_NAME} service..."
        systemctl stop "$SERVICE_NAME" || {
            print_error "Failed to stop service"
            return 1
        }
        print_status "Service stopped successfully"
    else
        print_warning "Service is not currently running"
    fi
    
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        print_status "Disabling ${SERVICE_NAME} service..."
        systemctl disable "$SERVICE_NAME" || {
            print_error "Failed to disable service"
            return 1
        }
        print_status "Service disabled successfully"
    else
        print_warning "Service is not enabled"
    fi
    
    return 0
}

# Remove systemd service file
remove_service_file() {
    print_header "Removing Service File"
    
    if [ -f "$SERVICE_FILE" ]; then
        print_status "Removing service file: $SERVICE_FILE"
        rm -f "$SERVICE_FILE" || {
            print_error "Failed to remove service file"
            return 1
        }
        print_status "Service file removed successfully"
        
        # Reload systemd daemon
        print_status "Reloading systemd daemon..."
        systemctl daemon-reload || {
            print_warning "Failed to reload systemd daemon (non-critical)"
        }
    else
        print_warning "Service file not found: $SERVICE_FILE"
    fi
    
    return 0
}

# Remove monitor script
remove_monitor_script() {
    print_header "Removing Monitor Script"
    
    if [ -f "$MONITOR_SCRIPT" ]; then
        print_status "Removing monitor script: $MONITOR_SCRIPT"
        rm -f "$MONITOR_SCRIPT" || {
            print_error "Failed to remove monitor script"
            return 1
        }
        print_status "Monitor script removed successfully"
    else
        print_warning "Monitor script not found: $MONITOR_SCRIPT"
    fi
    
    return 0
}

# Remove configuration file
remove_config_file() {
    print_header "Removing Configuration"
    
    if [ -f "$CONFIG_FILE" ]; then
        read -p "Remove configuration file? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Removing configuration file: $CONFIG_FILE"
            rm -f "$CONFIG_FILE" || {
                print_error "Failed to remove configuration file"
                return 1
            }
            print_status "Configuration file removed successfully"
        else
            print_status "Configuration file kept: $CONFIG_FILE"
        fi
    else
        print_warning "Configuration file not found: $CONFIG_FILE"
    fi
    
    return 0
}

# Remove audio files
remove_audio_files() {
    print_header "Removing Audio Files"
    
    local audio_files=("internet-yes.ul" "internet-no.ul")
    local files_found=0
    local files_to_remove=()
    
    # Check which files exist
    for audio_file in "${audio_files[@]}"; do
        if [ -f "${SOUND_DIR}/${audio_file}" ]; then
            files_found=1
            files_to_remove+=("${SOUND_DIR}/${audio_file}")
        fi
    done
    
    if [ $files_found -eq 1 ]; then
        print_status "Found audio files in: $SOUND_DIR"
        read -p "Remove audio files? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for audio_file in "${files_to_remove[@]}"; do
                print_status "Removing: $audio_file"
                rm -f "$audio_file" || {
                    print_error "Failed to remove: $audio_file"
                }
            done
            print_status "Audio files removed successfully"
        else
            print_status "Audio files kept"
        fi
    else
        print_warning "No audio files found in: $SOUND_DIR"
    fi
    
    return 0
}

# Remove log files
remove_log_files() {
    print_header "Removing Log Files"
    
    local log_files=("$LOG_FILE")
    local files_found=0
    
    # Check for rotated logs
    local i=1
    while [ -f "${LOG_FILE}.${i}" ]; do
        log_files+=("${LOG_FILE}.${i}")
        files_found=1
        i=$((i + 1))
    done
    
    if [ -f "$LOG_FILE" ]; then
        files_found=1
    fi
    
    if [ $files_found -eq 1 ]; then
        print_status "Found log file(s):"
        for log_file in "${log_files[@]}"; do
            if [ -f "$log_file" ]; then
                echo "  - $log_file"
            fi
        done
        
        read -p "Remove log files? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for log_file in "${log_files[@]}"; do
                if [ -f "$log_file" ]; then
                    print_status "Removing: $log_file"
                    rm -f "$log_file" || {
                        print_error "Failed to remove: $log_file"
                    }
                fi
            done
            print_status "Log files removed successfully"
        else
            print_status "Log files kept"
        fi
    else
        print_warning "No log files found"
    fi
    
    return 0
}

# Verify uninstall
verify_uninstall() {
    print_header "Verification"
    
    local errors=0
    
    # Check service
    if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
        print_error "Service file still exists"
        errors=1
    else
        print_status "Service file removed ✓"
    fi
    
    # Check monitor script
    if [ -f "$MONITOR_SCRIPT" ]; then
        print_error "Monitor script still exists: $MONITOR_SCRIPT"
        errors=1
    else
        print_status "Monitor script removed ✓"
    fi
    
    # Check if service is still running (shouldn't be, but verify)
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        print_warning "Service may still be running (try: systemctl stop $SERVICE_NAME)"
        errors=1
    else
        print_status "Service is stopped ✓"
    fi
    
    if [ $errors -eq 0 ]; then
        print_status "Uninstall verification completed successfully"
        return 0
    else
        print_warning "Some components may still exist. Please check manually."
        return 1
    fi
}

# Main uninstall function
main() {
    print_header "AllStarLink Internet Monitor Uninstaller"
    
    # Check if running as root
    check_root
    
    # Confirm uninstall
    echo
    print_warning "This will remove the Internet Monitor service and related files."
    echo
    read -p "Are you sure you want to continue? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Uninstall cancelled"
        exit 0
    fi
    
    echo
    
    # Perform uninstall steps
    stop_service
    remove_service_file
    remove_monitor_script
    remove_config_file
    remove_audio_files
    remove_log_files
    
    # Verify uninstall
    echo
    verify_uninstall
    
    echo
    print_header "Uninstall Complete"
    print_status "Internet Monitor has been removed from your system."
    print_status "Thank you for using Internet Monitor!"
    echo
    echo "73 and happy monitoring! 📻"
}

# Run main function
main "$@"

