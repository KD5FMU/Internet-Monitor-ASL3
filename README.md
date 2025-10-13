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
- **Local Audio Announcements**: Uses AllStarLink's audio system to announce status changes
- **Multiple Ping Targets**: Tests connectivity against multiple reliable servers (1.1.1.1, 8.8.8.8, 208.67.222.222)
- **Systemd Service**: Runs as a background service with automatic startup
- **Comprehensive Logging**: Detailed logs for troubleshooting and monitoring
- **Easy Configuration**: Simple setup process with guided installation
- **Robust Error Handling**: Enhanced reliability with proper error management

## 🚀 Quick Start

### Prerequisites
- AllStarLink ASL3+ node
- Linux system with systemd
- Root/sudo access

### Installation

1. **Download the installation script**:
   ```bash
   sudo wget https://raw.githubusercontent.com/KD5FMU/Internet-Monitor-ASL3/refs/heads/main/install_internet_monitor.sh
   ```

2. **Make it executable**:
   ```bash
   sudo chmod +x install_internet_monitor.sh
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

## ⚙️ Configuration

The service creates a configuration file at `/etc/internet-monitor.conf` with the following settings:

- `NODE_NUMBER`: Your AllStarLink node number
- `CHECK_INTERVAL`: How often to check connectivity (default: 180 seconds)
- `PING_HOSTS`: Servers to ping for connectivity testing

### Manual Configuration

You can edit the configuration file directly:
```bash
sudo nano /etc/internet-monitor.conf
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

## 🔧 Troubleshooting

### Check if the service is running
```bash
sudo systemctl status internet-monitor
```

### View recent logs
```bash
sudo tail -f /var/log/internet-monitor.log
```

### Test connectivity manually
```bash
ping -c 3 1.1.1.1
```

### Restart the service
```bash
sudo systemctl restart internet-monitor
```

## 🤝 Contributing

This project welcomes contributions! The current implementation is functional but could benefit from:

- Additional testing scenarios
- Enhanced error handling
- New features and improvements
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

