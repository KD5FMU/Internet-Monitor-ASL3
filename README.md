![Internet Monitor Logo](https://github.com/KD5FMU/Internet-Monitor-ASL3/blob/main/Internet%20Monitor.png)

# Internet Monitor for AllStarLink ASL3+

A robust internet connectivity monitoring service designed specifically for AllStarLink mobile nodes. This service automatically detects internet connection status and provides local audio announcements to keep operators informed of connectivity changes.

## 🎯 Purpose

**Problem Solved**: Mobile AllStarLink nodes often lose internet connectivity while traveling through areas with poor coverage. When this happens, operators become isolated from the network without knowing when connectivity is restored.

**Solution**: This service continuously monitors internet connectivity and provides immediate audio feedback when:
- Internet connection is lost
- Internet connection is restored

## ✨ Features

- **Automatic Monitoring**: Checks internet connectivity every 3 minutes (configurable)
- **Comprehensive Connectivity Testing**: Tests both ping connectivity and DNS resolution for reliable detection
- **Local Audio Announcements**: Uses AllStarLink's audio system to announce status changes
- **Multiple Ping Targets**: Tests connectivity against multiple reliable servers (1.1.1.1, 8.8.8.8, 208.67.222.222)
- **Automatic Log Rotation**: Logs are automatically rotated when they exceed 10MB to prevent disk space issues
- **Network Recovery**: Automatically attempts to restart NetworkManager when connectivity is lost
- **Systemd Service**: Runs as a background service with automatic startup and graceful shutdown
- **Comprehensive Logging**: Detailed logs for troubleshooting and monitoring
- **Easy Configuration**: Simple setup process with guided installation
- **Robust Error Handling**: Enhanced reliability with proper error management and validation
- **Command Validation**: Validates required system commands at startup

## 🚀 Quick Start

### Prerequisites
- AllStarLink ASL3+ node
- Linux system with systemd
- Root/sudo access

### Installation

1. **Download the installation script**:
   ```bash
   wget https://raw.githubusercontent.com/KD5FMU/Internet-Monitor-ASL3/refs/heads/main/install_internet_monitor.sh
   ```

2. **Make it executable**:
   ```bash
   chmod +x install_internet_monitor.sh
   ```

3. **Run the installer**:
   ```bash
   sudo ./install_internet_monitor.sh
   ```

4. **Follow the prompts** to configure your node number and check interval

5. **Test the service**:
   ```bash
   sudo systemctl status internet-monitor
   ```

## 🗑️ Uninstallation

If you need to remove the Internet Monitor service:

1. **Download the uninstall script**:
   ```bash
   wget https://raw.githubusercontent.com/KD5FMU/Internet-Monitor-ASL3/refs/heads/main/uninstall_internet_monitor.sh
   ```

2. **Make it executable**:
   ```bash
   chmod +x uninstall_internet_monitor.sh
   ```

3. **Run the uninstaller**:
   ```bash
   sudo ./uninstall_internet_monitor.sh
   ```

The uninstaller will:
- Stop and disable the service
- Remove the systemd service file and monitor script
- Optionally remove configuration, log, and audio files (with prompts)

**Note**: The uninstaller will prompt you before removing configuration, log, and audio files, allowing you to keep them if desired.

## ⚙️ Configuration

The service creates a configuration file at `/etc/internet-monitor.conf` with the following settings:

- `NODE_NUMBER`: Your AllStarLink node number (required, positive integer)
- `CHECK_INTERVAL`: How often to check connectivity in seconds (default: 180, minimum: 30)
- `PING_HOSTS`: Space-separated list of servers to ping for connectivity testing (default: "1.1.1.1 8.8.8.8 208.67.222.222")
- `SOUND_DIR`: Directory containing audio files (default: "/usr/share/asterisk/sounds/custom")
- `LOG_FILE`: Path to log file (default: "/var/log/internet-monitor.log")
- `ASTERISK_CLI`: Path to Asterisk CLI executable (default: "/usr/sbin/asterisk", auto-detected during install)
- `MAX_LOG_SIZE`: Maximum log file size in bytes before rotation (default: 10485760 = 10MB)
- `LOG_RETENTION`: Number of rotated log files to keep (default: 5)

### Manual Configuration

You can edit the configuration file directly:
```bash
sudo nano /etc/internet-monitor.conf
```

**⚠️ Important**: The configuration file is sourced directly by the script. Do not add commands, special shell characters (`;`, `&`, `|`, `<`, `>`), or unquoted values with spaces. Only simple variable assignments are allowed.

After modifying the configuration, restart the service:
```bash
sudo systemctl restart internet-monitor
```

## 📋 Service Management

### Start the service
```bash
sudo systemctl start internet-monitor
```

### Stop the service
```bash
sudo systemctl stop internet-monitor
```

### Enable auto-start
```bash
sudo systemctl enable internet-monitor
```

### Check service status
```bash
sudo systemctl status internet-monitor
```

### View logs
```bash
sudo journalctl -u internet-monitor -f
```

## 📁 File Locations

- **Service Script**: `/usr/local/bin/internet_monitor.sh`
- **Configuration**: `/etc/internet-monitor.conf`
- **Service File**: `/etc/systemd/system/internet-monitor.service`
- **Log File**: `/var/log/internet-monitor.log`
- **Rotated Logs**: `/var/log/internet-monitor.log.1`, `.2`, `.3`, etc. (automatic rotation)
- **Audio Files**: `/usr/share/asterisk/sounds/custom/internet-yes.ul` and `internet-no.ul`

## 🔧 Troubleshooting

### Check if the service is running
```bash
sudo systemctl status internet-monitor
```

### View recent logs
```bash
sudo tail -f /var/log/internet-monitor.log
```

Or use journalctl for systemd logs:
```bash
sudo journalctl -u internet-monitor -f
```

### View rotated logs
If logs have been rotated, check older log files:
```bash
sudo tail -f /var/log/internet-monitor.log.1
```

### Test connectivity manually
```bash
ping -c 3 1.1.1.1
```

### Test DNS resolution
```bash
getent hosts google.com
```

### Verify audio files exist
```bash
ls -la /usr/share/asterisk/sounds/custom/internet-*.ul
```

### Check Asterisk CLI path
```bash
which asterisk
# or
ls -la /usr/sbin/asterisk
```

If Asterisk is not found, update `ASTERISK_CLI` in `/etc/internet-monitor.conf` with the correct path.

### Restart the service
```bash
sudo systemctl restart internet-monitor
```

### Verify configuration
The service validates configuration on startup. Check logs for any validation errors:
```bash
sudo journalctl -u internet-monitor -n 50
```

## 🤝 Contributing

This project welcomes contributions! Current implementation includes:

- ✅ Comprehensive error handling and validation
- ✅ Automatic log rotation
- ✅ Graceful shutdown handling
- ✅ Network manager detection and recovery
- ✅ Multi-method DNS testing
- ✅ Command validation at startup

Areas that could benefit from additional contributions:

- Additional testing scenarios and edge cases
- Support for additional network managers beyond NetworkManager
- Performance optimizations
- Enhanced monitoring features
- Documentation improvements

**Please report issues and submit pull requests** - all contributions will be seriously considered to make the AllStarLink experience even better!

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Authors

- **Freddie Mac (KD5FMU)** - Original concept and development
- **Jory A. Pratt** - Enhanced implementation and reliability improvements

## 🙏 Acknowledgments

- AllStarLink community for feedback and testing
- Jory Pratt W5GLE for an Awesome Linux brain and support and encouragement

---

**73 and happy monitoring!** 📻

*This tool helps ensure you're never left in the dark about your internet connectivity while operating your mobile AllStarLink node.*

