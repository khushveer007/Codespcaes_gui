# Multi-OS GUI Master Script 🖥️

A comprehensive desktop environment setup script that supports multiple operating systems, desktop environments, and connection methods. Perfect for setting up remote desktop environments in GitHub Codespaces, containers, or virtual machines.

## 🌟 Features

### 🖥️ **Multiple Operating Systems**
- **Ubuntu 22.04 LTS** - Stable and user-friendly (~500MB)
- **Kali Linux Rolling** - Penetration testing focused (~1.5GB)
- **Arch Linux** - Bleeding edge and customizable (~800MB)
- **Debian 12 Bookworm** - Rock solid stability (~400MB)

### 🎨 **Desktop Environments**
- **XFCE** - Lightweight and fast (~200MB)
- **GNOME** - Modern and feature-rich (~800MB)
- **KDE Plasma** - Highly customizable (~1GB)
- **Hyprland** - Modern Wayland compositor (~300MB)
- **i3** - Tiling window manager (~150MB)
- **Cinnamon** - Traditional desktop (~600MB)
- **MATE** - Classic GNOME 2 fork (~400MB)
- **LXDE** - Extremely lightweight (~150MB)
- **Openbox** - Minimalist window manager (~100MB)

### 🔗 **Connection Methods**
- **noVNC** - Web-based VNC client (browser access)
- **VNC** - Traditional VNC protocol
- **RDP** - Remote Desktop Protocol
- **SSH** - Secure Shell terminal access
- **X11VNC** - X11 screen sharing

## 🚀 Quick Start

### 1. Make the script executable
```bash
chmod +x ubuntu-gui-master.sh
```

### 2. Run the interactive setup wizard
```bash
./ubuntu-gui-master.sh
```

That's it! The script will guide you through a 5-step wizard to configure everything.

## 📋 Usage

### Interactive Setup Wizard (Recommended)
```bash
./ubuntu-gui-master.sh setup
```
or simply:
```bash
./ubuntu-gui-master.sh
```

The wizard will ask you to:
1. **Choose Operating System** (Ubuntu, Kali, Arch, Debian)
2. **Select Desktop Environment** (XFCE, GNOME, KDE, etc.)
3. **Configure User Account** (username and password with root privileges)
4. **Choose Connection Methods** (noVNC, VNC, RDP, SSH, X11VNC)
5. **Confirm Installation** (review your choices before proceeding)

### Management Commands
```bash
# Check service status
./ubuntu-gui-master.sh status

# Start all configured services
./ubuntu-gui-master.sh start

# Stop all services
./ubuntu-gui-master.sh stop

# Restart all services
./ubuntu-gui-master.sh restart

# Show help
./ubuntu-gui-master.sh help
```

## 🔧 Step-by-Step Setup Guide

### Step 1: Operating System Selection
Choose from:
- **Ubuntu 22.04 LTS** - Best for general use, stable and reliable
- **Kali Linux** - Perfect for penetration testing and security research
- **Arch Linux** - For advanced users who want cutting-edge packages
- **Debian** - Rock-solid stability for production environments

### Step 2: Desktop Environment Selection
- **XFCE** - Recommended for beginners, fast and lightweight
- **GNOME** - Modern interface with lots of features
- **KDE** - Highly customizable with beautiful animations
- **i3/Hyprland** - For power users who prefer tiling window managers

### Step 3: User Account Configuration
- Enter a username (lowercase letters, numbers, hyphens, underscores)
- Set a secure password (minimum 6 characters)
- User will automatically get root privileges via sudo

### Step 4: Connection Methods
- **noVNC (Recommended)** - Access through web browser, no additional software needed
- **VNC** - Use traditional VNC clients like RealVNC or TigerVNC
- **RDP** - Connect using Windows Remote Desktop or similar clients
- **SSH** - Terminal access for command-line work
- **X11VNC** - Share existing X11 sessions

## 🌐 Accessing Your Desktop

### Web Browser (noVNC)
After setup, access your desktop at:
```
https://[codespace-name]-6080.app.github.dev/vnc.html
```

### VNC Client
Connect to:
```
Server: [codespace-name]-5901.app.github.dev:5901
```

### RDP Client
Connect to:
```
Server: [codespace-name]-3389.app.github.dev:3389
Username: [your-username]
Password: [your-password]
```

### SSH Access
```bash
ssh -p 2222 [username]@[codespace-name]-2222.app.github.dev
```

## 📱 Example Workflows

### For Web Development
```bash
# Choose Ubuntu + XFCE + noVNC for lightweight development
./ubuntu-gui-master.sh
# Select: Ubuntu → XFCE → your-username → noVNC
```

### For Penetration Testing
```bash
# Choose Kali Linux + XFCE + All connection methods
./ubuntu-gui-master.sh
# Select: Kali → XFCE → your-username → All Methods
```

### For Gaming/Graphics Work
```bash
# Choose Ubuntu + KDE + VNC for best graphics support
./ubuntu-gui-master.sh
# Select: Ubuntu → KDE → your-username → VNC + noVNC
```

## ⚡ Performance Tips

### Lightweight Setup (Low Resource Usage)
- **OS**: Debian or Ubuntu
- **Desktop**: XFCE or LXDE
- **Connection**: noVNC only
- **Total RAM**: ~1GB

### Full-Featured Setup
- **OS**: Ubuntu
- **Desktop**: GNOME or KDE
- **Connection**: All methods
- **Total RAM**: ~2-3GB

### Security-Focused Setup
- **OS**: Kali Linux
- **Desktop**: XFCE
- **Connection**: SSH + VNC
- **Extra Tools**: Yes

## 🛠️ Troubleshooting

### Services Not Starting
```bash
# Check current status
./ubuntu-gui-master.sh status

# Try restarting services
./ubuntu-gui-master.sh restart
```

### Can't Connect to Desktop
1. Verify services are running: `./ubuntu-gui-master.sh status`
2. Check if ports are open in your environment
3. Try different connection methods

### Desktop Environment Issues
```bash
# Stop all services and reconfigure
./ubuntu-gui-master.sh stop
./ubuntu-gui-master.sh setup
```

### Permission Issues
The script requires sudo privileges. Make sure you can run:
```bash
sudo apt update
```

## 📦 What Gets Installed

### Base Packages
- VNC server (TigerVNC)
- noVNC web interface
- SSH server
- RDP server (XRDP)
- Basic development tools

### Desktop-Specific Packages
- **XFCE**: File manager, terminal, text editor, Firefox
- **GNOME**: Full GNOME shell, applications, and utilities
- **KDE**: Plasma desktop, Dolphin, Konsole, Kate
- **Kali**: Security tools, penetration testing suite

### Security Tools (Kali Linux)
- Nmap, Wireshark, Burp Suite
- Metasploit Framework
- SQLMap, Nikto, Dirb
- Aircrack-ng, John the Ripper
- And many more...

## 🔒 Security Notes

- User accounts are created with sudo privileges
- SSH password authentication is enabled
- VNC connections are password-protected
- RDP connections use user authentication
- All services run on non-standard ports for security

## 🤝 Contributing

Feel free to submit issues, feature requests, or pull requests to improve this script!

## 📄 License

This project is open source and available under the MIT License.

---

**Happy Desktop Computing! 🎉**

For more help, run: `./ubuntu-gui-master.sh help`