#!/bin/bash

# Multi-OS GUI Master Script - Complete Desktop Environment Setup
# Supports Ubuntu, Kali, Arch, Debian with multiple Desktop Environments
# Author: GitHub Copilot Assistant
# Version: 4.0

set -e  # Exit on any error

# Configuration Variables
SELECTED_OS=""
SELECTED_DE=""
USERNAME=""
PASSWORD=""
CONNECTION_METHODS=()
VNC_DISPLAY=":1"
VNC_PORT="5901"
NOVNC_PORT="6080"
SSH_PORT="2222"
RDP_PORT="3389"
RESOLUTION="1920x1080"
INSTALL_EXTRA_TOOLS=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Print functions
print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              Multi-OS GUI Master Script                   ║"
    echo "║       Ubuntu • Kali • Arch • Debian Desktop Setup        ║"
    echo "║     GNOME • KDE • XFCE • Hyprland • i3 • Cinnamon        ║"
    echo "║        noVNC • VNC • RDP • SSH • X11VNC Support           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_fail() {
    echo -e "${RED}❌ $1${NC}"
}

# Utility functions
is_package_installed() {
    dpkg -l "$1" &> /dev/null
}

is_vnc_running() {
    pgrep -f "Xtigervnc.*${VNC_DISPLAY}" > /dev/null 2>&1
}

is_websockify_running() {
    pgrep -f "websockify.*${NOVNC_PORT}" > /dev/null 2>&1
}

is_ssh_running() {
    systemctl is-active --quiet ssh 2>/dev/null || service ssh status >/dev/null 2>&1
}

is_rdp_running() {
    systemctl is-active --quiet xrdp 2>/dev/null || service xrdp status >/dev/null 2>&1
}

validate_desktop() {
    case "$1" in
        "xfce"|"gnome"|"kde"|"kali"|"hyprland"|"i3"|"cinnamon"|"mate"|"lxde"|"openbox")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

validate_os() {
    case "$1" in
        "ubuntu"|"kali"|"arch"|"debian")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

get_os_info() {
    case "$1" in
        "ubuntu")
            echo "Ubuntu 22.04 LTS|ubuntu|apt|500MB|Stable and user-friendly"
            ;;
        "kali")
            echo "Kali Linux Rolling|kali|apt|1.5GB|Penetration testing focused"
            ;;
        "arch")
            echo "Arch Linux|arch|pacman|800MB|Bleeding edge and customizable"
            ;;
        "debian")
            echo "Debian 12 Bookworm|debian|apt|400MB|Rock solid stability"
            ;;
        *)
            echo "Unknown operating system: $1"
            return 1
            ;;
    esac
}

get_desktop_info() {
    case "$1" in
        "xfce")
            echo "XFCE|xfce4|xfce4-session|startxfce4|200MB|Lightweight and fast"
            ;;
        "gnome")
            echo "GNOME|gnome-shell|gnome-session|gnome-session|800MB|Modern and feature-rich"
            ;;
        "kde")
            echo "KDE Plasma|plasma-desktop|plasma-workspace|startplasma-x11|1GB|Highly customizable"
            ;;
        "hyprland")
            echo "Hyprland|hyprland|hyprland|Hyprland|300MB|Modern Wayland compositor"
            ;;
        "i3")
            echo "i3 Window Manager|i3|i3-wm|i3|150MB|Tiling window manager"
            ;;
        "cinnamon")
            echo "Cinnamon|cinnamon|cinnamon-session|cinnamon-session|600MB|Traditional desktop"
            ;;
        "mate")
            echo "MATE|mate-desktop|mate-session-manager|mate-session|400MB|Classic GNOME 2 fork"
            ;;
        "lxde")
            echo "LXDE|lxde|lxsession|startlxde|150MB|Extremely lightweight"
            ;;
        "openbox")
            echo "Openbox|openbox|openbox|openbox-session|100MB|Minimalist window manager"
            ;;
        *)
            echo "Unknown desktop environment: $1"
            return 1
            ;;
    esac
}

detect_running_desktop() {
    if pgrep -f "startxfce4" > /dev/null 2>&1; then
        echo "XFCE"
    elif pgrep -f "gnome-shell" > /dev/null 2>&1; then
        echo "GNOME"
    elif pgrep -f "startplasma" > /dev/null 2>&1; then
        echo "KDE"
    elif [ -f /etc/os-release ] && grep -q "kali" /etc/os-release; then
        echo "KALI"
    else
        echo "Unknown"
    fi
}

# Installation functions
install_base_packages() {
    print_header "INSTALLING BASE PACKAGES"
    
    print_status "Updating package list..."
    sudo apt update -qq
    
    # Install VNC server
    if is_package_installed "tigervnc-standalone-server"; then
        print_status "TigerVNC already installed"
    else
        print_status "Installing TigerVNC server..."
        sudo apt install -y tigervnc-standalone-server tigervnc-common
    fi
    
    # Install noVNC
    if is_package_installed "novnc"; then
        print_status "noVNC already installed"
    else
        print_status "Installing noVNC..."
        sudo apt install -y novnc websockify
    fi
    
    # Install SSH server
    if is_package_installed "openssh-server"; then
        print_status "SSH server already installed"
    else
        print_status "Installing SSH server..."
        sudo apt install -y openssh-server
    fi
    
    # Install RDP server
    if is_package_installed "xrdp"; then
        print_status "XRDP already installed"
    else
        print_status "Installing XRDP server..."
        sudo apt install -y xrdp
    fi
    
    # Install D-Bus X11 integration
    if is_package_installed "dbus-x11"; then
        print_status "D-Bus X11 already installed"
    else
        print_status "Installing D-Bus X11 integration..."
        sudo apt install -y dbus-x11
    fi
    
    print_success "Base packages installed"
}

install_desktop_environment() {
    local desktop=$1
    
    if ! validate_desktop "$desktop"; then
        print_error "Invalid desktop environment: $desktop"
        print_status "Available options: xfce, gnome, kde, kali"
        exit 1
    fi
    
    IFS='|' read -r DESKTOP_NAME MAIN_PACKAGE EXTRA_PACKAGES STARTUP_CMD DESKTOP_SESSION SIZE <<< "$(get_desktop_info "$desktop")"
    
    print_header "INSTALLING $DESKTOP_NAME DESKTOP ENVIRONMENT"
    print_warning "Download size: approximately $SIZE"
    
    if is_package_installed "$MAIN_PACKAGE"; then
        print_status "$DESKTOP_NAME desktop already installed"
        return
    fi
    
    print_status "Installing $DESKTOP_NAME desktop environment..."
    export DEBIAN_FRONTEND=noninteractive
    
    case "$desktop" in
        "xfce")
            sudo apt install -y xfce4 xfce4-goodies firefox gedit thunar-archive-plugin file-roller
            ;;
        "gnome")
            sudo apt install -y gnome-shell gnome-terminal nautilus gnome-control-center \
                                metacity gnome-tweaks firefox gedit file-roller
            ;;
        "kde")
            sudo apt install -y kde-plasma-desktop plasma-workspace plasma-widgets-addons \
                                dolphin konsole kate plasma-nm firefox ark okular
            ;;
        "kali")
            install_kali_linux
            ;;
    esac
    
    print_success "$DESKTOP_NAME desktop environment installed"
}

install_kali_linux() {
    print_header "INSTALLING KALI LINUX TOOLS AND DESKTOP"
    print_warning "This will add Kali repositories and install penetration testing tools"
    
    # Add Kali repositories
    print_status "Adding Kali Linux repositories..."
    if [ ! -f /etc/apt/sources.list.d/kali.list ]; then
        echo "deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/kali.list
        wget -q -O - https://archive.kali.org/archive-key.asc | sudo apt-key add -
        sudo apt update -qq
    fi
    
    # Install Kali desktop
    print_status "Installing Kali XFCE desktop environment..."
    sudo apt install -y kali-desktop-xfce
    
    # Install essential Kali tools
    print_status "Installing Kali penetration testing tools..."
    if [ "$KALI_TOOLS_ENABLED" = true ]; then
        sudo apt install -y kali-tools-top10 kali-tools-web kali-tools-wireless \
                           metasploit-framework nmap wireshark burpsuite \
                           sqlmap nikto dirb gobuster hydra john hashcat \
                           aircrack-ng recon-ng maltego zaproxy
    else
        sudo apt install -y kali-tools-top10 nmap wireshark-qt burpsuite sqlmap
    fi
    
    # Install browsers and utilities
    sudo apt install -y firefox-esr chromium thunar-archive-plugin file-roller
    
    print_success "Kali Linux environment installed"
}

# Configuration functions
configure_vnc() {
    print_header "CONFIGURING VNC ACCESS"
    
    # Create VNC directory for the user
    sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.vnc"
    
    # Create VNC startup script based on desktop environment
    create_vnc_startup_script
    
    # Set VNC password for the user
    echo "$PASSWORD" | sudo -u "$USERNAME" vncpasswd -f > "/home/$USERNAME/.vnc/passwd"
    sudo chmod 600 "/home/$USERNAME/.vnc/passwd"
    sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/.vnc/passwd"
    
    print_success "VNC configured for user $USERNAME"
}

create_vnc_startup_script() {
    local startup_script="/home/$USERNAME/.vnc/xstartup"
    
    print_status "Creating VNC startup script for $SELECTED_DE..."
    
    # Common header for all desktop environments
    sudo -u "$USERNAME" tee "$startup_script" > /dev/null << EOF
#!/bin/bash
export XKL_XMODMAP_DISABLE=1
export XDG_SESSION_TYPE=x11

[ -r \$HOME/.Xresources ] && xrdb \$HOME/.Xresources

if [ -z "\$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval \$(dbus-launch --sh-syntax)
    export DBUS_SESSION_BUS_ADDRESS
fi

EOF
    
    # Desktop environment specific configurations
    case "$SELECTED_DE" in
        "xfce")
            sudo -u "$USERNAME" tee -a "$startup_script" > /dev/null << 'EOF'
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export DESKTOP_SESSION=xfce
xsetroot -solid "#2E3440"
exec startxfce4
EOF
            ;;
        "gnome")
            sudo -u "$USERNAME" tee -a "$startup_script" > /dev/null << 'EOF'
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_DESKTOP=gnome
export DESKTOP_SESSION=gnome
export XDG_RUNTIME_DIR=/tmp/runtime-$USER
export LIBGL_ALWAYS_SOFTWARE=1
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
xsetroot -solid "#3465a4"
metacity &
sleep 2
gnome-shell --x11 --replace &
sleep 3
exec tail -f /dev/null
EOF
            ;;
        "kde")
            sudo -u "$USERNAME" tee -a "$startup_script" > /dev/null << 'EOF'
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_DESKTOP=KDE
export DESKTOP_SESSION=plasma
export KDE_FULL_SESSION=true
xsetroot -solid "#1d99f3"
exec startplasma-x11
EOF
            ;;
        "i3")
            sudo -u "$USERNAME" tee -a "$startup_script" > /dev/null << 'EOF'
export XDG_CURRENT_DESKTOP=i3
export XDG_SESSION_DESKTOP=i3
export DESKTOP_SESSION=i3
xsetroot -solid "#1e1e1e"
exec i3
EOF
            ;;
        "hyprland")
            sudo -u "$USERNAME" tee -a "$startup_script" > /dev/null << 'EOF'
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export WAYLAND_DISPLAY=wayland-1
exec Hyprland
EOF
            ;;
        *)
            # Default to XFCE for unknown desktop environments
            sudo -u "$USERNAME" tee -a "$startup_script" > /dev/null << 'EOF'
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export DESKTOP_SESSION=xfce
xsetroot -solid "#2E3440"
exec startxfce4
EOF
            ;;
    esac
    
    sudo chmod +x "$startup_script"
    sudo chown "$USERNAME:$USERNAME" "$startup_script"
}

configure_ssh() {
    print_header "CONFIGURING SSH ACCESS"
    
    # Configure SSH
    sudo sed -i 's/#Port 22/Port '"$SSH_PORT"'/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    
    # Enable and start SSH service
    sudo systemctl enable ssh
    sudo systemctl restart ssh
    
    print_success "SSH server configured and started on port $SSH_PORT"
}

configure_rdp() {
    print_header "CONFIGURING RDP ACCESS"
    
    # Configure XRDP
    sudo sed -i 's/port=3389/port='"$RDP_PORT"'/g' /etc/xrdp/xrdp.ini
    
    # Configure session
    echo "exec startxfce4" > ~/.xsession
    
    # Fix XRDP session issues
    sudo sed -i 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config
    
    # Enable and start XRDP service
    sudo systemctl enable xrdp
    sudo systemctl restart xrdp
    
    print_success "RDP server configured and started on port $RDP_PORT"
}

start_vnc_server() {
    print_header "STARTING VNC SERVER"
    
    if is_vnc_running; then
        print_status "VNC server already running on $VNC_DISPLAY"
        return
    fi
    
    print_status "Starting TigerVNC server on $VNC_DISPLAY..."
    
    if [ ! -f ~/.vnc/passwd ]; then
        print_warning "VNC password not set. You'll be prompted to create one."
        vncserver $VNC_DISPLAY -geometry $RESOLUTION -depth 24
    else
        vncserver $VNC_DISPLAY -geometry $RESOLUTION -depth 24
    fi
    
    sleep 3
    
    if is_vnc_running; then
        print_success "VNC server started successfully"
    else
        print_fail "Failed to start VNC server"
        return 1
    fi
}

start_novnc_server() {
    print_header "STARTING NOVNC WEB SERVER"
    
    if is_websockify_running; then
        print_status "noVNC already running on port $NOVNC_PORT"
        return
    fi
    
    print_status "Starting noVNC web interface..."
    websockify --web=/usr/share/novnc/ $NOVNC_PORT localhost:$VNC_PORT > /dev/null 2>&1 &
    sleep 3
    
    if is_websockify_running; then
        print_success "noVNC web server started successfully"
    else
        print_fail "Failed to start noVNC web server"
        return 1
    fi
}

start_remote_services() {
    print_header "STARTING REMOTE ACCESS SERVICES"
    
    # Start SSH
    if ! is_ssh_running; then
        configure_ssh
    else
        print_status "SSH server already running"
    fi
    
    # Start RDP
    if ! is_rdp_running; then
        configure_rdp
    else
        print_status "RDP server already running"
    fi
}

stop_services() {
    print_header "STOPPING SERVICES"
    
    print_status "Stopping VNC server..."
    vncserver -kill $VNC_DISPLAY 2>/dev/null || true
    
    print_status "Stopping noVNC..."
    pkill -f websockify 2>/dev/null || true
    
    stop_remote_services
    
    sleep 2
    print_success "All services stopped"
}

stop_remote_services() {
    print_status "Stopping SSH server..."
    sudo systemctl stop ssh 2>/dev/null || true
    
    print_status "Stopping RDP server..."
    sudo systemctl stop xrdp 2>/dev/null || true
}

# Status and information functions
show_status() {
    print_header "SERVICE STATUS"
    
    if is_vnc_running; then
        print_success "VNC Server: Running on $VNC_DISPLAY"
        current_desktop=$(detect_running_desktop)
        if [ "$current_desktop" != "Unknown" ]; then
            print_success "Desktop: $current_desktop"
        else
            print_warning "Desktop: Unknown"
        fi
    else
        print_fail "VNC Server: Not running"
    fi
    
    if is_websockify_running; then
        print_success "noVNC Web Interface: Running on port $NOVNC_PORT"
    else
        print_fail "noVNC Web Interface: Not running"
    fi
    
    if is_ssh_running; then
        print_success "SSH Server: Running on port $SSH_PORT"
    else
        print_fail "SSH Server: Not running"
    fi
    
    if is_rdp_running; then
        print_success "RDP Server: Running on port $RDP_PORT"
    else
        print_fail "RDP Server: Not running"
    fi
    
    if is_vnc_running && is_websockify_running; then
        echo ""
        print_header "ACCESS INFORMATION"
        echo -e "${CYAN}🌐 Web Access:${NC}"
        echo "   https://$CODESPACE_NAME-$NOVNC_PORT.app.github.dev/vnc.html"
        
        if is_ssh_running; then
            echo -e "${CYAN}🔐 SSH Access:${NC}"
            echo "   ssh -p $SSH_PORT username@$CODESPACE_NAME-$SSH_PORT.app.github.dev"
        fi
        
        if is_rdp_running; then
            echo -e "${CYAN}🖥️ RDP Access:${NC}"
            echo "   $CODESPACE_NAME-$RDP_PORT.app.github.dev:$RDP_PORT"
        fi
    fi
}

show_connection_info() {
    local desktop=$1
    IFS='|' read -r DESKTOP_NAME MAIN_PACKAGE EXTRA_PACKAGES STARTUP_CMD DESKTOP_SESSION SIZE <<< "$(get_desktop_info "$desktop")"
    
    print_header "CONNECTION INFORMATION"
    echo ""
    print_success "Ubuntu $DESKTOP_NAME GUI is now running!"
    echo ""
    echo -e "${CYAN}🌐 Access your desktop at:${NC}"
    echo -e "   ${BLUE}https://$CODESPACE_NAME-$NOVNC_PORT.app.github.dev/vnc.html${NC}"
    echo ""
    if is_ssh_running; then
        echo -e "${CYAN}🔐 SSH Access:${NC}"
        echo -e "   ${BLUE}ssh -p $SSH_PORT username@$CODESPACE_NAME-$SSH_PORT.app.github.dev${NC}"
        echo ""
    fi
    if is_rdp_running; then
        echo -e "${CYAN}�️ RDP Access:${NC}"
        echo -e "   ${BLUE}$CODESPACE_NAME-$RDP_PORT.app.github.dev:$RDP_PORT${NC}"
        echo ""
    fi
    echo -e "${CYAN}�📝 Usage Notes:${NC}"
    echo "   • Click 'Connect' in the noVNC interface"
    echo "   • Use your VNC password when prompted"
    echo "   • Desktop resolution: $RESOLUTION"
    echo "   • Desktop Environment: $DESKTOP_NAME"
    echo ""
    echo -e "${CYAN}🛠️ Management Commands:${NC}"
    echo "   • Stop: $0 stop"
    echo "   • Restart: $0 restart [$desktop]"
    echo "   • Status: $0 status"
    echo "   • Switch desktop: $0 start [xfce|gnome|kde|kali]"
    echo ""
    
    case "$desktop" in
        "xfce")
            echo -e "${CYAN}🖥️ XFCE Applications:${NC}"
            echo "   • Firefox web browser • Thunar file manager"
            echo "   • Mousepad text editor • Terminal • Application menu"
            ;;
        "gnome")
            echo -e "${CYAN}🖥️ GNOME Applications:${NC}"
            echo "   • Firefox web browser • Nautilus file manager"
            echo "   • Text editor (gedit) • GNOME Terminal • Activities overview"
            ;;
        "kde")
            echo -e "${CYAN}🖥️ KDE Applications:${NC}"
            echo "   • Firefox web browser • Dolphin file manager"
            echo "   • Kate text editor • Konsole terminal • Application launcher"
            ;;
        "kali")
            echo -e "${CYAN}🖥️ Kali Linux Tools:${NC}"
            echo "   • Firefox browser • Penetration testing tools"
            echo "   • Nmap • Wireshark • Burp Suite • SQLmap"
            echo "   • Metasploit • Aircrack-ng • John the Ripper"
            ;;
    esac
    echo ""
}

# Operating System Installation Functions
install_base_system() {
    print_header "INSTALLING BASE SYSTEM: $SELECTED_OS"
    
    case "$SELECTED_OS" in
        "ubuntu")
            install_ubuntu_base
            ;;
        "kali")
            install_kali_base
            ;;
        "arch")
            install_arch_base
            ;;
        "debian")
            install_debian_base
            ;;
    esac
}

install_ubuntu_base() {
    print_status "Setting up Ubuntu base system..."
    
    # Update package lists
    sudo apt update -qq
    
    # Install essential packages
    sudo apt install -y \
        curl wget git vim nano \
        build-essential software-properties-common \
        apt-transport-https ca-certificates \
        gnupg lsb-release
    
    print_success "Ubuntu base system installed"
}

install_kali_base() {
    print_status "Setting up Kali Linux base system..."
    
    # Add Kali repositories if not present
    if [ ! -f /etc/apt/sources.list.d/kali.list ]; then
        echo "deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/kali.list
        wget -q -O - https://archive.kali.org/archive-key.asc | sudo apt-key add -
    fi
    
    sudo apt update -qq
    
    # Install Kali base packages
    sudo apt install -y \
        kali-linux-core kali-linux-headless \
        curl wget git vim nano \
        build-essential
    
    if [[ "$INSTALL_EXTRA_TOOLS" == true ]]; then
        print_status "Installing additional Kali tools..."
        sudo apt install -y \
            kali-tools-top10 kali-tools-web kali-tools-wireless \
            metasploit-framework nmap wireshark burpsuite \
            sqlmap nikto dirb gobuster hydra john hashcat \
            aircrack-ng recon-ng maltego zaproxy
    fi
    
    print_success "Kali Linux base system installed"
}

install_arch_base() {
    print_status "Setting up Arch Linux base system..."
    
    # Update package database
    sudo pacman -Sy --noconfirm
    
    # Install essential packages
    sudo pacman -S --noconfirm \
        base-devel git vim nano \
        curl wget openssh \
        xorg-server xorg-xinit
    
    print_success "Arch Linux base system installed"
}

install_debian_base() {
    print_status "Setting up Debian base system..."
    
    sudo apt update -qq
    
    # Install essential packages
    sudo apt install -y \
        curl wget git vim nano \
        build-essential \
        apt-transport-https ca-certificates \
        gnupg lsb-release
    
    print_success "Debian base system installed"
}

# Desktop Environment Installation Functions
install_desktop_environment() {
    print_header "INSTALLING DESKTOP ENVIRONMENT: $SELECTED_DE"
    
    case "$SELECTED_OS" in
        "ubuntu"|"debian")
            install_de_debian_based
            ;;
        "kali")
            install_de_kali
            ;;
        "arch")
            install_de_arch
            ;;
    esac
}

install_de_debian_based() {
    export DEBIAN_FRONTEND=noninteractive
    
    case "$SELECTED_DE" in
        "xfce")
            sudo apt install -y xfce4 xfce4-goodies firefox-esr gedit thunar-archive-plugin file-roller
            ;;
        "gnome")
            sudo apt install -y gnome-shell gnome-terminal nautilus gnome-control-center \
                                metacity gnome-tweaks firefox-esr gedit file-roller
            ;;
        "kde")
            sudo apt install -y kde-plasma-desktop plasma-workspace plasma-widgets-addons \
                                dolphin konsole kate plasma-nm firefox-esr ark okular
            ;;
        "hyprland")
            # Add Hyprland repository for Debian/Ubuntu
            sudo apt install -y waybar wofi kitty firefox-esr
            # Note: Hyprland might need to be compiled from source on older systems
            ;;
        "i3")
            sudo apt install -y i3 i3status dmenu i3lock firefox-esr rxvt-unicode
            ;;
        "cinnamon")
            sudo apt install -y cinnamon firefox-esr
            ;;
        "mate")
            sudo apt install -y mate-desktop-environment firefox-esr
            ;;
        "lxde")
            sudo apt install -y lxde firefox-esr
            ;;
        "openbox")
            sudo apt install -y openbox obconf obmenu tint2 firefox-esr
            ;;
    esac
}

install_de_kali() {
    case "$SELECTED_DE" in
        "xfce")
            sudo apt install -y kali-desktop-xfce
            ;;
        "gnome")
            sudo apt install -y kali-desktop-gnome
            ;;
        "kde")
            sudo apt install -y kali-desktop-kde
            ;;
        *)
            # Default to XFCE for other DEs on Kali
            sudo apt install -y kali-desktop-xfce
            install_de_debian_based
            ;;
    esac
}

install_de_arch() {
    case "$SELECTED_DE" in
        "xfce")
            sudo pacman -S --noconfirm xfce4 xfce4-goodies firefox
            ;;
        "gnome")
            sudo pacman -S --noconfirm gnome gnome-extra firefox
            ;;
        "kde")
            sudo pacman -S --noconfirm plasma kde-applications firefox
            ;;
        "hyprland")
            sudo pacman -S --noconfirm hyprland waybar wofi kitty firefox
            ;;
        "i3")
            sudo pacman -S --noconfirm i3-wm i3status dmenu i3lock firefox rxvt-unicode
            ;;
        "cinnamon")
            sudo pacman -S --noconfirm cinnamon firefox
            ;;
        "mate")
            sudo pacman -S --noconfirm mate mate-extra firefox
            ;;
        "lxde")
            sudo pacman -S --noconfirm lxde firefox
            ;;
        "openbox")
            sudo pacman -S --noconfirm openbox obconf tint2 firefox
            ;;
    esac
}

# User Management Functions
create_user_account() {
    print_header "CREATING USER ACCOUNT"
    
    # Create user if doesn't exist
    if ! id "$USERNAME" &>/dev/null; then
        print_status "Creating user account: $USERNAME"
        sudo useradd -m -s /bin/bash "$USERNAME"
    else
        print_status "User $USERNAME already exists, updating configuration..."
    fi
    
    # Set password
    echo "$USERNAME:$PASSWORD" | sudo chpasswd
    
    # Add user to sudo group
    sudo usermod -aG sudo "$USERNAME"
    
    # Add user to additional groups for GUI access
    sudo usermod -aG audio,video,plugdev,users "$USERNAME"
    
    # Configure sudo without password for convenience (optional)
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$USERNAME"
    
    # Set up user directories
    sudo -u "$USERNAME" mkdir -p "/home/$USERNAME"/{Desktop,Documents,Downloads,Pictures,Videos}
    
    print_success "User account '$USERNAME' created with root privileges"
}

# Connection Method Installation Functions
install_connection_methods() {
    print_header "INSTALLING CONNECTION METHODS"
    
    for method in "${CONNECTION_METHODS[@]}"; do
        case "$method" in
            "novnc")
                install_novnc
                ;;
            "vnc")
                install_vnc_server
                ;;
            "rdp")
                install_rdp_server
                ;;
            "ssh")
                install_ssh_server
                ;;
            "x11vnc")
                install_x11vnc_server
                ;;
        esac
    done
}

install_novnc() {
    print_status "Installing noVNC web interface..."
    
    case "$SELECTED_OS" in
        "ubuntu"|"debian"|"kali")
            sudo apt install -y novnc websockify
            ;;
        "arch")
            # Install from AUR or manual installation
            sudo pacman -S --noconfirm python-websockify
            # Note: May need manual noVNC installation on Arch
            ;;
    esac
    
    print_success "noVNC installed"
}

install_vnc_server() {
    print_status "Installing VNC server..."
    
    case "$SELECTED_OS" in
        "ubuntu"|"debian"|"kali")
            sudo apt install -y tigervnc-standalone-server tigervnc-common
            ;;
        "arch")
            sudo pacman -S --noconfirm tigervnc
            ;;
    esac
    
    print_success "VNC server installed"
}

install_rdp_server() {
    print_status "Installing RDP server..."
    
    case "$SELECTED_OS" in
        "ubuntu"|"debian"|"kali")
            sudo apt install -y xrdp
            ;;
        "arch")
            sudo pacman -S --noconfirm xrdp
            ;;
    esac
    
    print_success "RDP server installed"
}

install_ssh_server() {
    print_status "Installing SSH server..."
    
    case "$SELECTED_OS" in
        "ubuntu"|"debian"|"kali")
            sudo apt install -y openssh-server
            ;;
        "arch")
            sudo pacman -S --noconfirm openssh
            ;;
    esac
    
    print_success "SSH server installed"
}

install_x11vnc_server() {
    print_status "Installing X11VNC server..."
    
    case "$SELECTED_OS" in
        "ubuntu"|"debian"|"kali")
            sudo apt install -y x11vnc
            ;;
        "arch")
            sudo pacman -S --noconfirm x11vnc
            ;;
    esac
    
    print_success "X11VNC server installed"
}

# Interactive Selection Functions
show_os_menu() {
    print_banner
    echo ""
    echo -e "${CYAN}Available Operating Systems:${NC}"
    echo ""
    echo -e "${GREEN}[1] Ubuntu 22.04 LTS${NC}     - Stable and user-friendly (~500MB)"
    echo "    • Latest LTS release with excellent hardware support"
    echo "    • Large software repository and community support"
    echo "    • Perfect for general desktop use"
    echo ""
    echo -e "${GREEN}[2] Kali Linux Rolling${NC}   - Penetration testing focused (~1.5GB)"
    echo "    • Complete penetration testing toolkit"
    echo "    • Pre-installed security and hacking tools"
    echo "    • Updated weekly with latest security tools"
    echo ""
    echo -e "${GREEN}[3] Arch Linux${NC}           - Bleeding edge and customizable (~800MB)"
    echo "    • Rolling release with latest packages"
    echo "    • Minimal base system with full customization"
    echo "    • Excellent documentation (Arch Wiki)"
    echo ""
    echo -e "${GREEN}[4] Debian 12 Bookworm${NC}  - Rock solid stability (~400MB)"
    echo "    • Extremely stable and reliable"
    echo "    • Conservative package updates"
    echo "    • Perfect for servers and production use"
    echo ""
}

show_desktop_menu() {
    echo ""
    echo -e "${CYAN}Available Desktop Environments:${NC}"
    echo ""
    echo -e "${GREEN}[1] XFCE${NC}          - Lightweight and fast (~200MB)"
    echo -e "${GREEN}[2] GNOME${NC}         - Modern and feature-rich (~800MB)"
    echo -e "${GREEN}[3] KDE Plasma${NC}    - Highly customizable (~1GB)"
    echo -e "${GREEN}[4] Hyprland${NC}      - Modern Wayland compositor (~300MB)"
    echo -e "${GREEN}[5] i3${NC}            - Tiling window manager (~150MB)"
    echo -e "${GREEN}[6] Cinnamon${NC}      - Traditional desktop (~600MB)"
    echo -e "${GREEN}[7] MATE${NC}          - Classic GNOME 2 fork (~400MB)"
    echo -e "${GREEN}[8] LXDE${NC}          - Extremely lightweight (~150MB)"
    echo -e "${GREEN}[9] Openbox${NC}       - Minimalist window manager (~100MB)"
    echo ""
}

show_connection_menu() {
    echo ""
    echo -e "${CYAN}Available Connection Methods:${NC}"
    echo ""
    echo -e "${GREEN}[1] noVNC (Web)${NC}    - Browser-based VNC client"
    echo -e "${GREEN}[2] VNC${NC}            - Traditional VNC protocol"
    echo -e "${GREEN}[3] RDP${NC}            - Remote Desktop Protocol"
    echo -e "${GREEN}[4] SSH${NC}            - Secure Shell terminal access"
    echo -e "${GREEN}[5] X11VNC${NC}         - X11 screen sharing"
    echo -e "${GREEN}[6] All Methods${NC}    - Install all connection types"
    echo ""
    echo "You can select multiple options (e.g., 1,3,4 or 'all' for everything)"
    echo ""
}

select_operating_system() {
    while true; do
        show_os_menu
        echo -n "Choose operating system (1-4) or 'q' to quit: "
        read -r choice
        
        case $choice in
            1)
                SELECTED_OS="ubuntu"
                break
                ;;
            2)
                SELECTED_OS="kali"
                echo ""
                print_warning "Kali Linux includes penetration testing tools"
                echo -n "Install additional security tools? (y/N): "
                read -r tools_confirm
                if [[ $tools_confirm =~ ^[Yy]$ ]]; then
                    INSTALL_EXTRA_TOOLS=true
                fi
                break
                ;;
            3)
                SELECTED_OS="arch"
                print_warning "Arch Linux requires more manual configuration"
                break
                ;;
            4)
                SELECTED_OS="debian"
                break
                ;;
            [qQ]|quit|exit)
                print_status "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please enter 1, 2, 3, 4, or 'q'"
                ;;
        esac
    done
    
    IFS='|' read -r OS_NAME _ _ SIZE DESCRIPTION <<< "$(get_os_info "$SELECTED_OS")"
    print_success "Selected: $OS_NAME - $DESCRIPTION"
}

select_desktop_environment() {
    while true; do
        show_desktop_menu
        echo -n "Choose desktop environment (1-9): "
        read -r choice
        
        case $choice in
            1) SELECTED_DE="xfce"; break ;;
            2) SELECTED_DE="gnome"; break ;;
            3) SELECTED_DE="kde"; break ;;
            4) SELECTED_DE="hyprland"; break ;;
            5) SELECTED_DE="i3"; break ;;
            6) SELECTED_DE="cinnamon"; break ;;
            7) SELECTED_DE="mate"; break ;;
            8) SELECTED_DE="lxde"; break ;;
            9) SELECTED_DE="openbox"; break ;;
            *)
                print_error "Invalid choice. Please enter 1-9"
                continue
                ;;
        esac
    done
    
    IFS='|' read -r DE_NAME _ _ _ SIZE DESCRIPTION <<< "$(get_desktop_info "$SELECTED_DE")"
    print_success "Selected: $DE_NAME - $DESCRIPTION"
}

configure_user_account() {
    echo ""
    print_header "USER ACCOUNT CONFIGURATION"
    echo ""
    
    while true; do
        echo -n "Enter username for the new user account: "
        read -r USERNAME
        
        if [[ -z "$USERNAME" ]]; then
            print_error "Username cannot be empty"
            continue
        fi
        
        if [[ ! "$USERNAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
            print_error "Username must start with a letter and contain only lowercase letters, numbers, hyphens, and underscores"
            continue
        fi
        
        if id "$USERNAME" &>/dev/null; then
            print_warning "User '$USERNAME' already exists. Continue anyway? (y/N): "
            read -r confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                continue
            fi
        fi
        
        break
    done
    
    while true; do
        echo -n "Enter password for user '$USERNAME': "
        read -s PASSWORD
        echo ""
        
        if [[ ${#PASSWORD} -lt 6 ]]; then
            print_error "Password must be at least 6 characters long"
            continue
        fi
        
        echo -n "Confirm password: "
        read -s PASSWORD_CONFIRM
        echo ""
        
        if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
            print_error "Passwords do not match"
            continue
        fi
        
        break
    done
    
    print_success "User account '$USERNAME' configured with root privileges"
}

select_connection_methods() {
    while true; do
        show_connection_menu
        echo -n "Select connection methods (comma-separated numbers or 'all'): "
        read -r choices
        
        CONNECTION_METHODS=()
        
        if [[ "$choices" == "all" || "$choices" == "6" ]]; then
            CONNECTION_METHODS=("novnc" "vnc" "rdp" "ssh" "x11vnc")
            break
        fi
        
        IFS=',' read -ra ADDR <<< "$choices"
        valid=true
        for choice in "${ADDR[@]}"; do
            choice=$(echo "$choice" | tr -d ' ')
            case $choice in
                1) CONNECTION_METHODS+=("novnc") ;;
                2) CONNECTION_METHODS+=("vnc") ;;
                3) CONNECTION_METHODS+=("rdp") ;;
                4) CONNECTION_METHODS+=("ssh") ;;
                5) CONNECTION_METHODS+=("x11vnc") ;;
                *)
                    print_error "Invalid choice: $choice"
                    valid=false
                    break
                    ;;
            esac
        done
        
        if [[ "$valid" == true && ${#CONNECTION_METHODS[@]} -gt 0 ]]; then
            break
        fi
    done
    
    print_success "Selected connection methods: ${CONNECTION_METHODS[*]}"
}

# Main installation and startup function
start_desktop() {
    local desktop=$1
    
    print_banner
    echo ""
    
    IFS='|' read -r DESKTOP_NAME MAIN_PACKAGE EXTRA_PACKAGES STARTUP_CMD DESKTOP_SESSION SIZE <<< "$(get_desktop_info "$desktop")"
    print_status "Selected desktop environment: $DESKTOP_NAME"
    echo ""
    
    # Install base packages
    install_base_packages
    
    # Install desktop environment
    install_desktop_environment "$desktop"
    
    # Configure VNC
    configure_vnc "$desktop"
    
    # Stop existing services
    stop_services
    
    # Start services
    if start_vnc_server && start_novnc_server; then
        start_remote_services
        show_connection_info "$desktop"
    else
        print_error "Failed to start some services"
        exit 1
    fi
}

# Interactive desktop selection
interactive_menu() {
    while true; do
        show_desktop_menu
        echo -e "${CYAN}Current Status:${NC}"
        if is_vnc_running; then
            current_desktop=$(detect_running_desktop)
            echo -e "  Running: ${GREEN}$current_desktop${NC}"
        else
            echo -e "  Status: ${RED}No desktop running${NC}"
        fi
        echo ""
        echo -n "Choose desktop environment (1-4) or 'q' to quit: "
        read -r choice
        
        case $choice in
            1)
                start_desktop "xfce"
                break
                ;;
            2)
                echo ""
                print_warning "GNOME requires ~800MB download"
                echo -n "Continue? (y/N): "
                read -r confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    start_desktop "gnome"
                    break
                fi
                ;;
            3)
                echo ""
                print_warning "KDE requires ~1GB download"
                echo -n "Continue? (y/N): "
                read -r confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    start_desktop "kde"
                    break
                fi
                ;;
            4)
                echo ""
                print_warning "Kali Linux requires ~1.5GB download"
                echo -n "Install full Kali tool collection? (y/N): "
                read -r tools_confirm
                if [[ $tools_confirm =~ ^[Yy]$ ]]; then
                    KALI_TOOLS_ENABLED=true
                fi
                echo -n "Continue with Kali installation? (y/N): "
                read -r confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    start_desktop "kali"
                    break
                fi
                ;;
            [qQ]|quit|exit)
                echo ""
                print_status "Goodbye!"
                exit 0
                ;;
            *)
                echo ""
                print_error "Invalid choice. Please enter 1, 2, 3, 4, or 'q'"
                echo ""
                ;;
        esac
    done
}

# Main script logic
main() {
    case "${1:-setup}" in
        "setup")
            comprehensive_setup
            ;;
        "status")
            show_current_status
            ;;
        "start")
            start_all_services
            ;;
        "stop")
            stop_all_services
            ;;
        "restart")
            stop_all_services
            sleep 2
            start_all_services
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Main Setup Function
comprehensive_setup() {
    print_banner
    echo ""
    print_header "COMPREHENSIVE SYSTEM SETUP"
    echo ""
    
    # Step 1: Select Operating System
    print_status "Step 1/5: Operating System Selection"
    select_operating_system
    echo ""
    
    # Step 2: Select Desktop Environment
    print_status "Step 2/5: Desktop Environment Selection"
    select_desktop_environment
    echo ""
    
    # Step 3: Configure User Account
    print_status "Step 3/5: User Account Configuration"
    configure_user_account
    echo ""
    
    # Step 4: Select Connection Methods
    print_status "Step 4/5: Connection Methods Selection"
    select_connection_methods
    echo ""
    
    # Step 5: Confirm Installation
    print_status "Step 5/5: Installation Confirmation"
    show_installation_summary
    echo ""
    
    echo -n "Proceed with installation? (y/N): "
    read -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
    
    # Perform Installation
    perform_installation
}

show_installation_summary() {
    echo ""
    print_header "INSTALLATION SUMMARY"
    echo ""
    
    IFS='|' read -r OS_NAME _ _ OS_SIZE OS_DESC <<< "$(get_os_info "$SELECTED_OS")"
    IFS='|' read -r DE_NAME _ _ _ DE_SIZE DE_DESC <<< "$(get_desktop_info "$SELECTED_DE")"
    
    echo -e "${CYAN}Operating System:${NC} $OS_NAME"
    echo -e "${CYAN}Description:${NC} $OS_DESC"
    echo -e "${CYAN}Download Size:${NC} ~$OS_SIZE"
    echo ""
    echo -e "${CYAN}Desktop Environment:${NC} $DE_NAME"
    echo -e "${CYAN}Description:${NC} $DE_DESC"
    echo -e "${CYAN}Additional Size:${NC} ~$DE_SIZE"
    echo ""
    echo -e "${CYAN}User Account:${NC} $USERNAME (with root privileges)"
    echo -e "${CYAN}Connection Methods:${NC} ${CONNECTION_METHODS[*]}"
    echo ""
    if [[ "$INSTALL_EXTRA_TOOLS" == true ]]; then
        echo -e "${YELLOW}Note: Additional security tools will be installed${NC}"
        echo ""
    fi
}

perform_installation() {
    echo ""
    print_header "STARTING INSTALLATION PROCESS"
    echo ""
    
    # Install base system
    install_base_system
    
    # Install desktop environment
    install_desktop_environment
    
    # Create user account
    create_user_account
    
    # Install connection methods
    install_connection_methods
    
    # Configure services
    configure_all_services
    
    # Start services
    start_all_services
    
    # Show final information
    show_final_info
}

configure_all_services() {
    print_header "CONFIGURING SERVICES"
    
    # Configure each selected connection method
    for method in "${CONNECTION_METHODS[@]}"; do
        case "$method" in
            "vnc"|"novnc")
                configure_vnc
                ;;
            "rdp")
                configure_rdp_service
                ;;
            "ssh")
                configure_ssh_service
                ;;
            "x11vnc")
                configure_x11vnc_service
                ;;
        esac
    done
}

configure_rdp_service() {
    print_status "Configuring RDP service..."
    
    # Configure XRDP
    sudo sed -i "s/port=3389/port=$RDP_PORT/g" /etc/xrdp/xrdp.ini
    
    # Configure session for the user
    echo "exec startxfce4" | sudo -u "$USERNAME" tee "/home/$USERNAME/.xsession" > /dev/null
    
    # Fix XRDP session issues
    if [ -f /etc/X11/Xwrapper.config ]; then
        sudo sed -i 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config
    fi
    
    print_success "RDP service configured"
}

configure_ssh_service() {
    print_status "Configuring SSH service..."
    
    # Configure SSH
    sudo sed -i "s/#Port 22/Port $SSH_PORT/g" /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    
    print_success "SSH service configured"
}

configure_x11vnc_service() {
    print_status "Configuring X11VNC service..."
    
    # Create X11VNC password file for the user
    echo "$PASSWORD" | sudo -u "$USERNAME" x11vnc -storepasswd "/home/$USERNAME/.x11vnc_passwd"
    
    print_success "X11VNC service configured"
}

start_all_services() {
    print_header "STARTING SERVICES"
    
    for method in "${CONNECTION_METHODS[@]}"; do
        case "$method" in
            "vnc")
                start_vnc_service
                ;;
            "novnc")
                start_vnc_service
                start_novnc_service
                ;;
            "rdp")
                start_rdp_service
                ;;
            "ssh")
                start_ssh_service
                ;;
            "x11vnc")
                start_x11vnc_service
                ;;
        esac
    done
}

start_vnc_service() {
    print_status "Starting VNC server..."
    
    # Start VNC server as the created user
    sudo -u "$USERNAME" vncserver "$VNC_DISPLAY" -geometry "$RESOLUTION" -depth 24
    
    sleep 3
    
    if is_vnc_running; then
        print_success "VNC server started successfully"
    else
        print_fail "Failed to start VNC server"
    fi
}

start_novnc_service() {
    print_status "Starting noVNC web interface..."
    
    websockify --web=/usr/share/novnc/ "$NOVNC_PORT" "localhost:$VNC_PORT" > /dev/null 2>&1 &
    sleep 3
    
    if is_websockify_running; then
        print_success "noVNC web server started successfully"
    else
        print_fail "Failed to start noVNC web server"
    fi
}

start_rdp_service() {
    print_status "Starting RDP server..."
    
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl enable xrdp
        sudo systemctl start xrdp
    else
        sudo service xrdp start
    fi
    
    print_success "RDP server started"
}

start_ssh_service() {
    print_status "Starting SSH server..."
    
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl enable ssh
        sudo systemctl start ssh
    else
        sudo service ssh start
    fi
    
    print_success "SSH server started"
}

start_x11vnc_service() {
    print_status "Starting X11VNC server..."
    
    # Start X11VNC as the user (requires active X session)
    sudo -u "$USERNAME" x11vnc -display :0 -rfbauth "/home/$USERNAME/.x11vnc_passwd" -forever -shared -bg
    
    print_success "X11VNC server started"
}

show_final_info() {
    print_banner
    echo ""
    print_success "INSTALLATION COMPLETED SUCCESSFULLY!"
    echo ""
    
    IFS='|' read -r OS_NAME _ _ _ _ <<< "$(get_os_info "$SELECTED_OS")"
    IFS='|' read -r DE_NAME _ _ _ _ _ <<< "$(get_desktop_info "$SELECTED_DE")"
    
    print_header "SYSTEM INFORMATION"
    echo -e "${CYAN}Operating System:${NC} $OS_NAME"
    echo -e "${CYAN}Desktop Environment:${NC} $DE_NAME"
    echo -e "${CYAN}Username:${NC} $USERNAME (with root privileges)"
    echo -e "${CYAN}Resolution:${NC} $RESOLUTION"
    echo ""
    
    print_header "CONNECTION INFORMATION"
    
    for method in "${CONNECTION_METHODS[@]}"; do
        case "$method" in
            "novnc")
                echo -e "${GREEN}🌐 noVNC (Web Browser):${NC}"
                echo "   https://$CODESPACE_NAME-$NOVNC_PORT.app.github.dev/vnc.html"
                echo ""
                ;;
            "vnc")
                echo -e "${GREEN}🖥️ VNC Client:${NC}"
                echo "   Server: $CODESPACE_NAME-$VNC_PORT.app.github.dev:$VNC_PORT"
                echo "   Password: [Your VNC password]"
                echo ""
                ;;
            "rdp")
                echo -e "${GREEN}🖥️ RDP Connection:${NC}"
                echo "   Server: $CODESPACE_NAME-$RDP_PORT.app.github.dev:$RDP_PORT"
                echo "   Username: $USERNAME"
                echo "   Password: [Your user password]"
                echo ""
                ;;
            "ssh")
                echo -e "${GREEN}🔐 SSH Access:${NC}"
                echo "   ssh -p $SSH_PORT $USERNAME@$CODESPACE_NAME-$SSH_PORT.app.github.dev"
                echo "   Password: [Your user password]"
                echo ""
                ;;
            "x11vnc")
                echo -e "${GREEN}📺 X11VNC:${NC}"
                echo "   Display sharing of current X session"
                echo "   Password: [Your X11VNC password]"
                echo ""
                ;;
        esac
    done
    
    print_header "MANAGEMENT COMMANDS"
    echo "• Status: $0 status"
    echo "• Stop: $0 stop"
    echo "• Restart: $0 restart"
    echo "• New Setup: $0 setup"
    echo ""
}

show_current_status() {
    print_header "CURRENT SYSTEM STATUS"
    
    if is_vnc_running; then
        print_success "VNC Server: Running on $VNC_DISPLAY"
    else
        print_fail "VNC Server: Not running"
    fi
    
    if is_websockify_running; then
        print_success "noVNC Web Interface: Running on port $NOVNC_PORT"
    else
        print_fail "noVNC Web Interface: Not running"
    fi
    
    if is_ssh_running; then
        print_success "SSH Server: Running on port $SSH_PORT"
    else
        print_fail "SSH Server: Not running"
    fi
    
    if is_rdp_running; then
        print_success "RDP Server: Running on port $RDP_PORT"
    else
        print_fail "RDP Server: Not running"
    fi
    
    # Check for X11VNC
    if pgrep -f "x11vnc" > /dev/null 2>&1; then
        print_success "X11VNC Server: Running"
    else
        print_fail "X11VNC Server: Not running"
    fi
    
    if [[ -n "$USERNAME" ]]; then
        echo ""
        print_header "USER INFORMATION"
        echo -e "${CYAN}Username:${NC} $USERNAME"
        if id "$USERNAME" &>/dev/null; then
            print_success "User account exists"
        else
            print_fail "User account not found"
        fi
    fi
}

stop_all_services() {
    print_header "STOPPING ALL SERVICES"
    
    print_status "Stopping VNC server..."
    vncserver -kill $VNC_DISPLAY 2>/dev/null || true
    
    print_status "Stopping noVNC..."
    pkill -f websockify 2>/dev/null || true
    
    print_status "Stopping X11VNC..."
    pkill -f x11vnc 2>/dev/null || true
    
    print_status "Stopping SSH server..."
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl stop ssh 2>/dev/null || true
    else
        sudo service ssh stop 2>/dev/null || true
    fi
    
    print_status "Stopping RDP server..."
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl stop xrdp 2>/dev/null || true
    else
        sudo service xrdp stop 2>/dev/null || true
    fi
    
    sleep 2
    print_success "All services stopped"
}

show_help() {
    print_banner
    echo ""
    echo "Multi-OS GUI Master Script - Complete Desktop Environment Setup"
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo "  $0 [COMMAND]"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo "  setup        Interactive setup wizard (default, recommended for first use)"
    echo "  status       Show current service status"
    echo "  start        Start all configured services"
    echo "  stop         Stop all services"
    echo "  restart      Restart all services"
    echo "  help         Show this help message"
    echo ""
    echo -e "${CYAN}Supported Operating Systems:${NC}"
    echo "  • Ubuntu 22.04 LTS    - Stable and user-friendly"
    echo "  • Kali Linux Rolling  - Penetration testing focused"
    echo "  • Arch Linux          - Bleeding edge and customizable"
    echo "  • Debian 12 Bookworm  - Rock solid stability"
    echo ""
    echo -e "${CYAN}Supported Desktop Environments:${NC}"
    echo "  • XFCE        - Lightweight and fast"
    echo "  • GNOME       - Modern and feature-rich"
    echo "  • KDE Plasma  - Highly customizable"
    echo "  • Hyprland    - Modern Wayland compositor"
    echo "  • i3          - Tiling window manager"
    echo "  • Cinnamon    - Traditional desktop"
    echo "  • MATE        - Classic GNOME 2 fork"
    echo "  • LXDE        - Extremely lightweight"
    echo "  • Openbox     - Minimalist window manager"
    echo ""
    echo -e "${CYAN}Supported Connection Methods:${NC}"
    echo "  • noVNC       - Web-based VNC client (browser access)"
    echo "  • VNC         - Traditional VNC protocol"
    echo "  • RDP         - Remote Desktop Protocol"
    echo "  • SSH         - Secure Shell terminal access"
    echo "  • X11VNC      - X11 screen sharing"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  $0                    # Start interactive setup wizard"
    echo "  $0 setup              # Start interactive setup wizard"
    echo "  $0 status             # Check current service status"
    echo "  $0 start              # Start all configured services"
    echo "  $0 stop               # Stop all services"
    echo ""
    echo -e "${YELLOW}First Time Usage:${NC}"
    echo "  Run '$0' or '$0 setup' to start the interactive configuration wizard."
    echo "  The wizard will guide you through selecting your OS, desktop"
    echo "  environment, creating a user account, and configuring access methods."
    echo ""
}

# Execute main function with all arguments
main "$@"
