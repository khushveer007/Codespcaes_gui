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
    case "$SELECTED_OS" in
        "arch")
            # For Arch, check if the package or any package in the group is installed
            if pacman -Q "$1" &> /dev/null; then
                return 0
            elif pacman -Qg "$1" &> /dev/null; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            dpkg -l "$1" &> /dev/null
            ;;
    esac
}

is_vnc_running() {
    pgrep -f "Xtigervnc.*${VNC_DISPLAY}" > /dev/null 2>&1
}

is_websockify_running() {
    pgrep -f "websockify.*${NOVNC_PORT}" > /dev/null 2>&1
}

is_ssh_running() {
    if [[ "$SELECTED_OS" == "arch" ]]; then
        systemctl is-active --quiet sshd 2>/dev/null
    else
        systemctl is-active --quiet ssh 2>/dev/null || service ssh status >/dev/null 2>&1
    fi
}

is_rdp_running() {
    case "$SELECTED_OS" in
        "arch")
            # RDP not available on Arch, always return false
            return 1
            ;;
        *)
            systemctl is-active --quiet xrdp 2>/dev/null || service xrdp status >/dev/null 2>&1
            ;;
    esac
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
        "kali")
            echo "Kali Linux Tools|kali-tools|kali-desktop-xfce|startxfce4|1.5GB|Penetration testing focused"
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

# Package environment configuration for Debian-based systems
configure_package_environment() {
    print_status "Configuring package installation environment..."
    
    case "$SELECTED_OS" in
        "ubuntu"|"debian"|"kali")
            # Set environment variables to handle package installation issues
            export DEBIAN_FRONTEND=noninteractive
            export DEBCONF_NONINTERACTIVE_SEEN=true
            export UCF_FORCE_CONFFOLD=YES
            
            # Prevent USB device detection errors in container environments
            if [ ! -d "/sys/bus/usb/devices" ] || [ -z "$(ls -A /sys/bus/usb/devices/ 2>/dev/null)" ]; then
                print_status "Container environment detected - configuring USB device handling..."
                sudo mkdir -p /sys/bus/usb/devices/dummy 2>/dev/null || true
                
                # Create minimal USB device files to prevent detection errors
                for interface_file in bInterfaceClass bInterfaceSubClass bInterfaceProtocol; do
                    if [ ! -f "/sys/bus/usb/devices/dummy/$interface_file" ]; then
                        echo "09" | sudo tee "/sys/bus/usb/devices/dummy/$interface_file" >/dev/null 2>&1 || true
                    fi
                done
            fi
            
            # Handle dpkg-divert usr-merge conflicts
            print_status "Checking for usr-merge conflicts..."
            if dpkg-divert --list | grep -q "lib32.*usr-is-merged"; then
                print_warning "Detected usr-merge diversion conflicts, attempting to resolve..."
                
                # Try to remove conflicting diversions safely
                sudo dpkg-divert --remove --rename /lib32 2>/dev/null || true
                
                # Ensure lib32 symlink exists if needed
                if [ ! -e /lib32 ] && [ -d /usr/lib32 ]; then
                    sudo ln -sf /usr/lib32 /lib32 2>/dev/null || true
                fi
            fi
            
            # Configure debconf to minimize interactive prompts
            echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections 2>/dev/null || true
            
            # Update package cache with error handling
            print_status "Updating package lists with enhanced error handling..."
            if ! sudo apt update -qq 2>/dev/null; then
                print_warning "Initial package update failed, trying with different options..."
                sudo apt clean
                sudo apt update --fix-missing -qq 2>/dev/null || {
                    print_warning "Package update had issues, continuing with existing cache..."
                }
            fi
            ;;
        *)
            # For Arch and other systems, minimal configuration
            export DEBIAN_FRONTEND=noninteractive
            ;;
    esac
    
    print_success "Package environment configured"
}

# Safe package installation wrapper with enhanced error handling
safe_apt_install() {
    local packages=("$@")
    local retry_count=0
    local max_retries=3
    
    print_status "Installing packages: ${packages[*]}"
    
    while [ $retry_count -lt $max_retries ]; do
        # Capture both stdout and stderr to a log file
        if sudo apt install -y "${packages[@]}" 2>&1 | tee /tmp/apt_install.log; then
            print_success "Packages installed successfully: ${packages[*]}"
            return 0
        else
            retry_count=$((retry_count + 1))
            print_warning "Package installation attempt $retry_count failed"
            
            # Check for specific errors and handle them
            if grep -q "dpkg-divert.*usr-is-merged" /tmp/apt_install.log; then
                print_status "Detected usr-merge conflict, attempting to fix..."
                sudo dpkg --configure -a 2>/dev/null || true
                
                # Try to resolve usr-merge conflicts more aggressively
                sudo dpkg-divert --list | grep "usr-is-merged" | while read line; do
                    path=$(echo "$line" | cut -d' ' -f3)
                    print_status "Removing diversion for: $path"
                    sudo dpkg-divert --remove "$path" 2>/dev/null || true
                done
                
                # Fix broken packages
                sudo apt --fix-broken install -y 2>/dev/null || true
            fi
            
            if grep -q "bInterfaceClass.*No such file" /tmp/apt_install.log; then
                print_status "USB device detection error detected, creating dummy files..."
                sudo mkdir -p /sys/bus/usb/devices/dummy 2>/dev/null || true
                for interface_file in bInterfaceClass bInterfaceSubClass bInterfaceProtocol; do
                    echo "09" | sudo tee "/sys/bus/usb/devices/dummy/$interface_file" >/dev/null 2>&1 || true
                done
            fi
            
            if grep -q "package pre-installation script subprocess returned error" /tmp/apt_install.log; then
                print_status "Package pre-installation script error detected, trying recovery..."
                # Try to clean package cache and fix broken packages
                sudo apt clean
                sudo apt autoclean
                sudo apt --fix-broken install -y 2>/dev/null || true
                # Force configure pending packages
                sudo dpkg --configure -a 2>/dev/null || true
            fi
            
            if [ $retry_count -lt $max_retries ]; then
                print_status "Retrying package installation in 5 seconds..."
                sleep 5
                sudo apt update -qq 2>/dev/null || true
            else
                print_error "Failed to install packages after $max_retries attempts: ${packages[*]}"
                print_status "Last error log:"
                tail -10 /tmp/apt_install.log 2>/dev/null || true
                print_status "Continuing with installation, some features may not work..."
                return 1
            fi
        fi
    done
}

# Installation functions
install_base_packages() {
    print_header "INSTALLING BASE PACKAGES"
    
    # Configure environment to handle common Debian package issues
    configure_package_environment
    
    case "$SELECTED_OS" in
        "arch")
            print_status "Updating package database..."
            sudo pacman -Sy --noconfirm
            
            # Install essential tools first
            print_status "Installing essential tools..."
            sudo pacman -S --noconfirm openssl which
            
            # Install VNC server
            if pacman -Q tigervnc &> /dev/null; then
                print_status "TigerVNC already installed"
            else
                print_status "Installing TigerVNC server..."
                sudo pacman -S --noconfirm tigervnc
            fi
            
            # Install X11 components
            print_status "Installing X11 components..."
            sudo pacman -S --noconfirm xorg-server xorg-xinit xorg-xauth
            
            # Install SSH server
            if pacman -Q openssh &> /dev/null; then
                print_status "SSH server already installed"
            else
                print_status "Installing SSH server..."
                sudo pacman -S --noconfirm openssh
            fi
            
            # Install RDP server (from AUR if needed)
            if pacman -Q xrdp &> /dev/null; then
                print_status "XRDP already installed"
            else
                print_status "Installing XRDP server..."
                # Try to install xrdp, if not available, skip with warning
                sudo pacman -S --noconfirm xrdp 2>/dev/null || print_warning "XRDP not available in official repos, skipping..."
            fi
            
            # Install process management tools
            print_status "Installing process management tools..."
            sudo pacman -S --noconfirm procps-ng
            ;;
        *)
            print_status "Updating package list..."
            sudo apt update -qq
            
            # Install essential tools first
            print_status "Installing essential tools..."
            safe_apt_install openssl procps
            
            # Install VNC server
            if is_package_installed "tigervnc-standalone-server"; then
                print_status "TigerVNC already installed"
            else
                print_status "Installing TigerVNC server..."
                safe_apt_install tigervnc-standalone-server tigervnc-common
            fi
            
            # Install noVNC
            if is_package_installed "novnc"; then
                print_status "noVNC already installed"
            else
                print_status "Installing noVNC..."
                safe_apt_install novnc websockify
            fi
            
            # Install SSH server
            if is_package_installed "openssh-server"; then
                print_status "SSH server already installed"
            else
                print_status "Installing SSH server..."
                safe_apt_install openssh-server
            fi
            
            # Install RDP server
            if is_package_installed "xrdp"; then
                print_status "XRDP already installed"
            else
                print_status "Installing XRDP server..."
                safe_apt_install xrdp
            fi
            
            # Install D-Bus X11 integration and related packages
            local dbus_packages=("dbus-x11" "dbus-user-session" "dbus" "at-spi2-core")
            for pkg in "${dbus_packages[@]}"; do
                if is_package_installed "$pkg"; then
                    print_status "$pkg already installed"
                else
                    print_status "Installing $pkg..."
                    safe_apt_install "$pkg" || print_warning "Failed to install $pkg, continuing..."
                fi
            done
            
            # Install additional session management packages
            local session_packages=("systemd" "systemd-logind" "policykit-1")
            for pkg in "${session_packages[@]}"; do
                if is_package_installed "$pkg"; then
                    print_status "$pkg already installed"
                else
                    print_status "Installing $pkg..."
                    safe_apt_install "$pkg" || print_warning "Failed to install $pkg, continuing..."
                fi
            done
            ;;
    esac
    
    print_success "Base packages installed"
}

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
    safe_apt_install kali-desktop-xfce
    
    # Install essential Kali tools
    print_status "Installing Kali penetration testing tools..."
    if [ "$KALI_TOOLS_ENABLED" = true ]; then
        safe_apt_install kali-tools-top10 kali-tools-web kali-tools-wireless \
                           metasploit-framework nmap wireshark burpsuite \
                           sqlmap nikto dirb gobuster hydra john hashcat \
                           aircrack-ng recon-ng maltego zaproxy
    else
        safe_apt_install kali-tools-top10 nmap wireshark-qt burpsuite sqlmap
    fi
    
    # Install browsers and utilities
    local firefox_package=""
    if apt list firefox-esr 2>/dev/null | grep -q "firefox-esr/"; then
        firefox_package="firefox-esr"
    elif command -v snap >/dev/null 2>&1; then
        print_status "Installing Firefox via snap..."
        sudo snap install firefox 2>/dev/null || firefox_package="chromium-browser"
    else
        firefox_package="chromium-browser"
    fi
    
    if [[ -n "$firefox_package" ]]; then
        safe_apt_install "$firefox_package" chromium thunar-archive-plugin file-roller
    else
        safe_apt_install chromium thunar-archive-plugin file-roller
    fi
    
    print_success "Kali Linux environment installed"
}

install_de_debian_based() {
    export DEBIAN_FRONTEND=noninteractive
    
    # Determine which firefox package to use based on availability
    local firefox_package=""
    
    # Check for firefox-esr first (Debian/older Ubuntu)
    if apt list firefox-esr 2>/dev/null | grep -q "firefox-esr/"; then
        firefox_package="firefox-esr"
    # Check if we can use snap for firefox (Ubuntu 24.04+)
    elif command -v snap >/dev/null 2>&1; then
        print_status "Installing Firefox via snap..."
        sudo snap install firefox 2>/dev/null || {
            print_warning "Failed to install Firefox via snap, using chromium instead"
            firefox_package="chromium-browser"
        }
    else
        # Fallback to chromium or other browsers
        if apt list chromium-browser 2>/dev/null | grep -q "chromium-browser/"; then
            firefox_package="chromium-browser"
        elif apt list chromium 2>/dev/null | grep -q "chromium/"; then
            firefox_package="chromium"
        else
            print_warning "No suitable browser package found, skipping browser installation"
            firefox_package=""
        fi
    fi
    
    case "$SELECTED_DE" in
        "xfce")
            if [[ -n "$firefox_package" ]]; then
                safe_apt_install xfce4 xfce4-goodies "$firefox_package" gedit thunar-archive-plugin file-roller
            else
                safe_apt_install xfce4 xfce4-goodies gedit thunar-archive-plugin file-roller
            fi
            ;;
        "gnome")
            if [[ -n "$firefox_package" ]]; then
                safe_apt_install gnome-shell gnome-terminal nautilus gnome-control-center \
                                    metacity gnome-tweaks "$firefox_package" gedit file-roller
            else
                safe_apt_install gnome-shell gnome-terminal nautilus gnome-control-center \
                                    metacity gnome-tweaks gedit file-roller
            fi
            ;;
        "kde")
            if [[ -n "$firefox_package" ]]; then
                safe_apt_install kde-plasma-desktop plasma-workspace plasma-widgets-addons \
                                    dolphin konsole kate plasma-nm "$firefox_package" ark okular
            else
                safe_apt_install kde-plasma-desktop plasma-workspace plasma-widgets-addons \
                                    dolphin konsole kate plasma-nm ark okular
            fi
            ;;
        "hyprland")
            # Add Hyprland repository for Debian/Ubuntu
            if [[ -n "$firefox_package" ]]; then
                safe_apt_install waybar wofi kitty "$firefox_package"
            else
                safe_apt_install waybar wofi kitty
            fi
            # Note: Hyprland might need to be compiled from source on older systems
            ;;
        "i3")
            if [[ -n "$firefox_package" ]]; then
                safe_apt_install i3 i3status dmenu i3lock "$firefox_package" rxvt-unicode
            else
                safe_apt_install i3 i3status dmenu i3lock rxvt-unicode
            fi
            ;;
        "cinnamon")
            if [[ -n "$firefox_package" ]]; then
                safe_apt_install cinnamon "$firefox_package"
            else
                safe_apt_install cinnamon
            fi
            ;;
        "mate")
            if [[ -n "$firefox_package" ]]; then
                safe_apt_install mate-desktop-environment "$firefox_package"
            else
                safe_apt_install mate-desktop-environment
            fi
            ;;
        "lxde")
            if [[ -n "$firefox_package" ]]; then
                safe_apt_install lxde "$firefox_package"
            else
                safe_apt_install lxde
            fi
            ;;
        "openbox")
            if [[ -n "$firefox_package" ]]; then
                safe_apt_install openbox obconf obmenu tint2 "$firefox_package"
            else
                safe_apt_install openbox obconf obmenu tint2
            fi
            ;;
    esac
    print_success "$SELECTED_DE desktop environment installed"
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
    print_success "Kali $SELECTED_DE desktop environment installed"
}

install_de_arch() {
    local packages_to_install=()
    
    case "$SELECTED_DE" in
        "xfce")
            packages_to_install=(xfce4 xfce4-goodies firefox thunar-archive-plugin file-roller)
            ;;
        "gnome")
            packages_to_install=(gnome gnome-tweaks firefox)
            ;;
        "kde")
            packages_to_install=(plasma kde-applications firefox)
            ;;
        "hyprland")
            packages_to_install=(hyprland waybar wofi kitty firefox)
            ;;
        "i3")
            packages_to_install=(i3-wm i3status dmenu i3lock firefox rxvt-unicode)
            ;;
        "cinnamon")
            packages_to_install=(cinnamon firefox)
            ;;
        "mate")
            packages_to_install=(mate mate-extra firefox)
            ;;
        "lxde")
            packages_to_install=(lxde firefox)
            ;;
        "openbox")
            packages_to_install=(openbox obconf tint2 firefox)
            ;;
        "kali")
            # For Arch, "kali" means installing a base DE (XFCE) and security tools
            print_status "Installing XFCE as a base for Kali tools..."
            packages_to_install=(xfce4 xfce4-goodies firefox)
            ;;
    esac

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        print_status "Installing packages for $SELECTED_DE: ${packages_to_install[*]}"
        sudo pacman -S --noconfirm --needed "${packages_to_install[@]}"
    fi

    if [[ "$SELECTED_DE" == "kali" ]]; then
        install_kali_tools_arch
    fi
    
    print_success "$SELECTED_DE desktop environment installed on Arch"
}

install_kali_tools_arch() {
    print_header "INSTALLING KALI-LIKE TOOLS ON ARCH"
    print_warning "This installs a selection of security tools from the official Arch repositories."
    
    local security_tools=(
        nmap metasploit wireshark-qt burpsuite sqlmap
        nikto dirb gobuster hydra john hashcat aircrack-ng
        recon-ng owasp-zap
    )

    print_status "Installing security tools: ${security_tools[*]}"
    sudo pacman -S --noconfirm --needed "${security_tools[@]}"
    
    print_success "Security tools installed"
}

# Configuration functions
configure_vnc() {
    print_header "CONFIGURING VNC ACCESS"
    
    # Ensure VNC server is installed before configuring
    ensure_vnc_installed
    
    # Create VNC directory for the user
    sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.vnc"
    
    # Create VNC startup script based on desktop environment
    create_vnc_startup_script
    
    # Set VNC password for the user - use the most reliable method
    print_status "Setting VNC password..."
    if command -v vncpasswd >/dev/null 2>&1; then
        # Use interactive vncpasswd method that works consistently
        sudo -u "$USERNAME" bash -c "
            cd /home/$USERNAME
            expect << 'EOF' >/dev/null 2>&1 || {
                # If expect is not available, use printf method
                printf '%s\n%s\nn\n' '$PASSWORD' '$PASSWORD' | vncpasswd
            }
spawn vncpasswd
expect \"Password:\"
send \"$PASSWORD\r\"
expect \"Verify:\"
send \"$PASSWORD\r\"
expect \"Would you like to enter a view-only password\"
send \"n\r\"
expect eof
EOF
        " || {
            # Final fallback - use vncpasswd -f if available
            print_status "Using fallback VNC password method..."
            echo "$PASSWORD" | sudo -u "$USERNAME" vncpasswd -f > "/home/$USERNAME/.vnc/passwd" 2>/dev/null
        }
        
        # Ensure correct permissions
        sudo chmod 600 "/home/$USERNAME/.vnc/passwd" 2>/dev/null || true
        sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/.vnc/passwd" 2>/dev/null || true
        
        if [ -f "/home/$USERNAME/.vnc/passwd" ]; then
            print_success "VNC password configured successfully"
        else
            print_error "Failed to create VNC password file"
            return 1
        fi
    else
        print_error "vncpasswd command not found"
        return 1
    fi
    
    # Ensure correct permissions
    sudo chmod 600 "/home/$USERNAME/.vnc/passwd"
    sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/.vnc/passwd"
    
    print_success "VNC configured for user $USERNAME"
}

# Ensure VNC server is properly installed
ensure_vnc_installed() {
    print_status "Ensuring VNC server is properly installed..."
    
    case "$SELECTED_OS" in
        "arch")
            if ! command -v vncserver >/dev/null 2>&1; then
                print_status "Installing TigerVNC server..."
                sudo pacman -S --noconfirm tigervnc
            fi
            
            if ! command -v vncpasswd >/dev/null 2>&1; then
                print_warning "vncpasswd not found, will use alternative password method"
                # Ensure openssl is available for password generation
                if ! command -v openssl >/dev/null 2>&1; then
                    sudo pacman -S --noconfirm openssl
                fi
            fi
            ;;
        *)
            if ! command -v vncserver >/dev/null 2>&1; then
                print_status "Installing TigerVNC server..."
                sudo apt update -qq
                sudo apt install -y tigervnc-standalone-server tigervnc-common
            fi
            ;;
    esac
    
    print_success "VNC server installation verified"
}

create_vnc_startup_script() {
    local startup_script="/home/$USERNAME/.vnc/xstartup"
    
    print_status "Creating VNC startup script for $SELECTED_DE..."
    
    # Ensure /etc/X11/Xresources exists to prevent compilation errors
    if [ ! -f /etc/X11/Xresources ]; then
        print_status "Creating missing /etc/X11/Xresources file..."
        sudo mkdir -p /etc/X11
        sudo tee /etc/X11/Xresources > /dev/null << 'XRES_EOF'
! X11 Resources file
! Basic X11 settings
*customization: -color
XRES_EOF
    fi
    
    # Common header for all desktop environments
    sudo -u "$USERNAME" tee "$startup_script" > /dev/null << EOF
#!/bin/bash
export XKL_XMODMAP_DISABLE=1
export XDG_SESSION_TYPE=x11
export HOME=/home/$USERNAME
export USER=$USERNAME

# Source system defaults - with error handling
[ -r /etc/X11/Xresources ] && xrdb /etc/X11/Xresources 2>/dev/null || true
[ -r \$HOME/.Xresources ] && xrdb \$HOME/.Xresources 2>/dev/null || true

# D-Bus session setup with enhanced error handling and fallbacks
if [ -z "\$DBUS_SESSION_BUS_ADDRESS" ]; then
    # Ensure D-Bus machine ID exists
    if [ ! -f /var/lib/dbus/machine-id ] && [ ! -f /etc/machine-id ]; then
        # Try to create machine ID files if possible
        if command -v dbus-uuidgen >/dev/null 2>&1; then
            dbus-uuidgen 2>/dev/null | sudo tee /var/lib/dbus/machine-id > /dev/null 2>&1 || true
            dbus-uuidgen 2>/dev/null | sudo tee /etc/machine-id > /dev/null 2>&1 || true
        fi
    fi
    
    # Try dbus-launch first (most reliable)
    if command -v dbus-launch >/dev/null 2>&1; then
        eval \$(dbus-launch --sh-syntax 2>/dev/null) && export DBUS_SESSION_BUS_ADDRESS || {
            # Fallback: try manual D-Bus session setup
            export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-session-\$USER-\$\$"
            if command -v dbus-daemon >/dev/null 2>&1; then
                dbus-daemon --session --address="\$DBUS_SESSION_BUS_ADDRESS" --nofork --nopidfile --syslog-only 2>/dev/null &
                sleep 2
            fi
        }
    else
        print_warning "dbus-launch not found, desktop components may not work properly"
    fi
fi

# Ensure D-Bus session is accessible and update environment
if [ -n "\$DBUS_SESSION_BUS_ADDRESS" ]; then
    export DBUS_SESSION_BUS_ADDRESS
    # Update D-Bus activation environment if possible
    command -v dbus-update-activation-environment >/dev/null 2>&1 && \\
        dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE 2>/dev/null || true
fi

# Start user D-Bus services if systemd is available
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user import-environment DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE 2>/dev/null || true
    systemctl --user start dbus.service 2>/dev/null || true
fi

# Set XDG environment
export XDG_CONFIG_HOME=\$HOME/.config
export XDG_DATA_HOME=\$HOME/.local/share
export XDG_CACHE_HOME=\$HOME/.cache

# Create necessary directories
mkdir -p \$HOME/.config \$HOME/.local/share \$HOME/.cache

EOF
    
    # Desktop environment specific configurations
    case "$SELECTED_DE" in
        "xfce")
            sudo -u "$USERNAME" tee -a "$startup_script" > /dev/null << 'EOF'
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export DESKTOP_SESSION=xfce

# Set XDG runtime directory with proper permissions
export XDG_RUNTIME_DIR=/tmp/runtime-$USER
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Ensure D-Bus session is working
if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
    echo "D-Bus session address: $DBUS_SESSION_BUS_ADDRESS" > /tmp/vnc-dbus-debug.log
    dbus-monitor --session &
    DBUS_MONITOR_PID=$!
    echo "D-Bus monitor started with PID: $DBUS_MONITOR_PID" >> /tmp/vnc-dbus-debug.log
else
    echo "Warning: No D-Bus session address found" > /tmp/vnc-dbus-debug.log
fi

# Start XFCE components with error logging
xsetroot -solid "#2E3440"

# Start XFCE session with D-Bus error handling
echo "Starting XFCE session..." >> /tmp/vnc-dbus-debug.log
exec startxfce4 2>&1 | tee -a /tmp/vnc-xfce-debug.log
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
            # Hyprland is a Wayland compositor, fallback to XFCE for VNC compatibility
            print_warning "Hyprland (Wayland) is not compatible with VNC. Using XFCE fallback for VNC session."
            sudo -u "$USERNAME" tee -a "$startup_script" > /dev/null << 'EOF'
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export DESKTOP_SESSION=xfce
export XDG_SESSION_TYPE=x11
xsetroot -solid "#2E3440"
exec startxfce4
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
    
    # Configure session for the created user
    echo "exec startxfce4" | sudo -u "$USERNAME" tee "/home/$USERNAME/.xsession" > /dev/null
    sudo chmod +x "/home/$USERNAME/.xsession"
    
    # Fix XRDP session issues
    if [ -f /etc/X11/Xwrapper.config ]; then
        sudo sed -i 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config
    fi
    
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
    
    print_status "Starting TigerVNC server on $VNC_DISPLAY as user $USERNAME..."
    
    # Ensure the user has a password file
    if [ ! -f "/home/$USERNAME/.vnc/passwd" ]; then
        print_warning "VNC password not set for user $USERNAME. Configuring VNC first..."
        configure_vnc
    fi
    
    # Start VNC server as the created user
    sudo -u "$USERNAME" bash -c "
        export HOME=/home/$USERNAME
        export USER=$USERNAME
        cd /home/$USERNAME
        vncserver $VNC_DISPLAY -geometry $RESOLUTION -depth 24 -localhost no 2>/dev/null
    " || {
        print_error "Failed to start VNC server"
        return 1
    }
    
    sleep 3
    
    if is_vnc_running; then
        print_success "VNC server started successfully"
    else
        print_fail "Failed to start VNC server"
        # Try to get more debugging info
        print_status "Checking VNC log for errors..."
        if [ -f "/home/$USERNAME/.vnc/"*"$VNC_DISPLAY.log" ]; then
            tail -5 "/home/$USERNAME/.vnc/"*"$VNC_DISPLAY.log" 2>/dev/null || true
        fi
        return 1
    fi
}

start_novnc_server() {
    print_header "STARTING NOVNC WEB SERVER"
    
    if is_websockify_running; then
        print_status "noVNC already running on port $NOVNC_PORT"
        return
    fi
    
    # Check if websockify is available
    if ! command -v websockify >/dev/null 2>&1; then
        print_error "websockify command not found. Installing..."
        case "$SELECTED_OS" in
            "arch")
                sudo pacman -S --noconfirm python-websockify || {
                    print_error "Failed to install websockify on Arch"
                    return 1
                }
                ;;
            *)
                sudo apt install -y websockify || {
                    print_error "Failed to install websockify"
                    return 1
                }
                ;;
        esac
    fi
    
    # Find noVNC web directory
    local novnc_web_dir=""
    if [ -d "/usr/share/novnc" ]; then
        novnc_web_dir="/usr/share/novnc"
    elif [ -d "/usr/share/novnc/web" ]; then
        novnc_web_dir="/usr/share/novnc/web"
    elif [ -d "/usr/local/share/novnc" ]; then
        novnc_web_dir="/usr/local/share/novnc"
    else
        print_error "noVNC web directory not found"
        return 1
    fi
    
    print_status "Starting noVNC web interface using $novnc_web_dir..."
    websockify --web="$novnc_web_dir" "$NOVNC_PORT" "localhost:$VNC_PORT" > /dev/null 2>&1 &
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
    # First try to stop VNC using the USERNAME if set
    if [[ -n "$USERNAME" ]]; then
        sudo -u "$USERNAME" vncserver -kill "$VNC_DISPLAY" 2>/dev/null || true
    fi
    
    # Also kill any running VNC processes (fallback)
    pkill -f "Xtigervnc.*:1" 2>/dev/null || true
    pkill -f "vncserver.*:1" 2>/dev/null || true
    
    print_status "Stopping noVNC..."
    pkill -f websockify 2>/dev/null || true
    
    print_status "Stopping X11VNC..."
    pkill -f x11vnc 2>/dev/null || true
    
    stop_remote_services
    
    sleep 2
    print_success "All services stopped"
}

stop_remote_services() {
    print_status "Stopping SSH server..."
    if [[ "$SELECTED_OS" == "arch" ]]; then
        sudo systemctl stop sshd 2>/dev/null || true
    else
        sudo systemctl stop ssh 2>/dev/null || true
    fi
    
    print_status "Stopping RDP server..."
    case "$SELECTED_OS" in
        "arch")
            # RDP not available on Arch, skip
            ;;
        *)
            sudo systemctl stop xrdp 2>/dev/null || true
            ;;
    esac
}

# Status and information functions
check_dbus_status() {
    print_header "D-BUS DIAGNOSTIC INFORMATION"
    
    # Check D-Bus system service
    if systemctl is-active --quiet dbus; then
        print_success "D-Bus system service: Running"
    else
        print_fail "D-Bus system service: Not running"
        print_status "Attempting to start D-Bus system service..."
        sudo systemctl start dbus || print_warning "Failed to start D-Bus system service"
    fi
    
    # Check D-Bus machine ID
    if [ -f /var/lib/dbus/machine-id ] || [ -f /etc/machine-id ]; then
        print_success "D-Bus machine ID: Present"
    else
        print_fail "D-Bus machine ID: Missing"
        print_status "Creating D-Bus machine ID..."
        sudo dbus-uuidgen | sudo tee /var/lib/dbus/machine-id > /dev/null 2>&1 || true
        sudo dbus-uuidgen | sudo tee /etc/machine-id > /dev/null 2>&1 || true
    fi
    
    # Check user D-Bus session if username is set
    if [[ -n "$USERNAME" ]]; then
        print_status "Checking D-Bus session for user: $USERNAME"
        
        # Check if user has D-Bus session
        if sudo -u "$USERNAME" bash -c 'pgrep -u "$USER" dbus-daemon > /dev/null 2>&1'; then
            print_success "User D-Bus session: Running"
        else
            print_warning "User D-Bus session: Not detected"
        fi
        
        # Check D-Bus environment for user
        if sudo -u "$USERNAME" bash -c '[ -n "$DBUS_SESSION_BUS_ADDRESS" ]' 2>/dev/null; then
            print_success "User D-Bus environment: Configured"
        else
            print_warning "User D-Bus environment: Not configured"
        fi
        
        # Check systemd user session
        if command -v systemctl >/dev/null 2>&1; then
            if sudo -u "$USERNAME" systemctl --user is-active --quiet dbus 2>/dev/null; then
                print_success "User systemd D-Bus service: Running"
            else
                print_warning "User systemd D-Bus service: Not running"
            fi
        fi
        
        # Check debug logs if they exist
        if [ -f /tmp/vnc-dbus-debug.log ]; then
            print_status "VNC D-Bus debug log found:"
            echo -e "${CYAN}$(cat /tmp/vnc-dbus-debug.log)${NC}"
        fi
        
        if [ -f /tmp/vnc-xfce-debug.log ]; then
            print_status "VNC XFCE debug log found (last 10 lines):"
            echo -e "${CYAN}$(tail -10 /tmp/vnc-xfce-debug.log)${NC}"
        fi
    fi
    
    echo ""
}

show_status() {
    check_dbus_status
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
    safe_apt_install curl wget git vim nano \
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
    safe_apt_install kali-linux-core kali-linux-headless \
        curl wget git vim nano \
        build-essential
    
    if [[ "$INSTALL_EXTRA_TOOLS" == true ]]; then
        print_status "Installing additional Kali tools..."
        safe_apt_install kali-tools-top10 kali-tools-web kali-tools-wireless \
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
        xorg-server xorg-xinit xorg-xauth \
        openssl which procps-ng \
        python python-pip
    
    # Install pipx for Python package management
    if ! command -v pipx >/dev/null 2>&1; then
        print_status "Installing pipx for Python package management..."
        sudo pacman -S --noconfirm python-pipx
    fi
    
    # Ensure sudo is configured for wheel group
    if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
        print_status "Configuring sudo for wheel group..."
        echo "%wheel ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
    fi
    
    print_success "Arch Linux base system installed"
}

install_debian_base() {
    print_status "Setting up Debian base system..."
    
    sudo apt update -qq
    
    # Install essential packages
    safe_apt_install curl wget git vim nano \
        build-essential \
        apt-transport-https ca-certificates \
        gnupg lsb-release
    
    print_success "Debian base system installed"
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
    
    # Add user to appropriate admin group based on OS
    if [[ "$SELECTED_OS" == "arch" ]]; then
        # Arch Linux uses 'wheel' group for sudo privileges
        sudo usermod -aG wheel "$USERNAME"
    else
        # Debian-based systems use 'sudo' group
        sudo usermod -aG sudo "$USERNAME"
    fi
    
    # Add user to additional groups for GUI access (only add groups that exist)
    local groups_to_add=""
    for group in audio video plugdev users input storage optical; do
        if getent group "$group" >/dev/null 2>&1; then
            if [[ -n "$groups_to_add" ]]; then
                groups_to_add="${groups_to_add},${group}"
            else
                groups_to_add="$group"
            fi
        fi
    done
    
    if [[ -n "$groups_to_add" ]]; then
        print_status "Adding user to groups: $groups_to_add"
        sudo usermod -aG "$groups_to_add" "$USERNAME"
    fi
    
    # Configure sudo without password for convenience (optional)
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$USERNAME"
    
    # Set up user directories
    sudo -u "$USERNAME" mkdir -p "/home/$USERNAME"/{Desktop,Documents,Downloads,Pictures,Videos}
    
    # Initialize D-Bus environment for the user
    print_status "Setting up D-Bus environment for user $USERNAME..."
    
    # Ensure D-Bus machine ID exists
    if [ ! -f /var/lib/dbus/machine-id ] && [ ! -f /etc/machine-id ]; then
        print_status "Creating D-Bus machine ID..."
        sudo dbus-uuidgen | sudo tee /var/lib/dbus/machine-id > /dev/null 2>&1 || true
        sudo dbus-uuidgen | sudo tee /etc/machine-id > /dev/null 2>&1 || true
    fi
    
    # Create D-Bus configuration directory for user
    sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.config/dbus"
    
    # Set up systemd user session if available
    if command -v systemctl >/dev/null 2>&1; then
        # Enable lingering for the user (allows user services to start at boot)
        sudo loginctl enable-linger "$USERNAME" 2>/dev/null || true
        
        # Create user systemd directory
        sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.config/systemd/user"
    fi
    
    # Create .profile for D-Bus environment variables
    sudo -u "$USERNAME" tee "/home/$USERNAME/.profile" > /dev/null << 'EOF'
# D-Bus session configuration
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ] && command -v dbus-launch >/dev/null 2>&1; then
    eval $(dbus-launch --sh-syntax)
    export DBUS_SESSION_BUS_ADDRESS
fi

# XDG directories
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime-$USER}

# Create runtime directory if it doesn't exist
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
fi
EOF
    
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
            safe_apt_install novnc websockify
            ;;
        "arch")
            # Install Python websockify via pacman (more reliable than pipx)
            print_status "Installing websockify and dependencies..."
            sudo pacman -S --noconfirm python-websockify
            
            # Download and set up noVNC manually
            print_status "Setting up noVNC..."
            if [ ! -d /usr/share/novnc ]; then
                sudo mkdir -p /usr/share/novnc
                sudo pacman -S --noconfirm git
                cd /tmp
                sudo git clone https://github.com/novnc/noVNC.git novnc-download 2>/dev/null || {
                    print_warning "Git clone failed, downloading noVNC archive..."
                    sudo pacman -S --noconfirm wget
                    sudo wget -O novnc.tar.gz https://github.com/novnc/noVNC/archive/refs/heads/master.tar.gz
                    sudo tar -xzf novnc.tar.gz
                    sudo mv noVNC-master novnc-download
                }
                sudo cp -r novnc-download/* /usr/share/novnc/
                sudo rm -rf novnc-download novnc.tar.gz 2>/dev/null || true
                sudo chmod +x /usr/share/novnc/utils/novnc_proxy 2>/dev/null || true
            fi
            ;;
    esac
    
    print_success "noVNC installed"
}

install_vnc_server() {
    print_status "Installing VNC server..."
    
    case "$SELECTED_OS" in
        "ubuntu"|"debian"|"kali")
            safe_apt_install tigervnc-standalone-server tigervnc-common
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
            safe_apt_install xrdp
            ;;
        "arch")
            # xrdp is available in AUR, install from there or skip for Arch
            print_warning "RDP (xrdp) is not available in official Arch repositories"
            print_status "Installing alternative RDP solution (freerdp)..."
            sudo pacman -S --noconfirm freerdp
            print_status "Note: For full RDP server functionality on Arch, you may need to install xrdp from AUR"
            ;;
    esac
    
    print_success "RDP server components installed"
}

install_ssh_server() {
    print_status "Installing SSH server..."
    
    case "$SELECTED_OS" in
        "ubuntu"|"debian"|"kali")
            safe_apt_install openssh-server
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
            safe_apt_install x11vnc
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
    echo -e "${GREEN}[4] Kali Tools${NC}    - Security tools with XFCE (~1.5GB)"
    echo -e "${GREEN}[5] Hyprland${NC}      - Modern Wayland compositor (~300MB)"
    echo -e "${GREEN}[6] i3${NC}            - Tiling window manager (~150MB)"
    echo -e "${GREEN}[7] Cinnamon${NC}      - Traditional desktop (~600MB)"
    echo -e "${GREEN}[8] MATE${NC}          - Classic GNOME 2 fork (~400MB)"
    echo -e "${GREEN}[9] LXDE${NC}          - Extremely lightweight (~150MB)"
    echo -e "${GREEN}[10] Openbox${NC}      - Minimalist window manager (~100MB)"
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
        echo -n "Choose desktop environment (1-10): "
        read -r choice
        
        case $choice in
            1) SELECTED_DE="xfce"; break ;;
            2) SELECTED_DE="gnome"; break ;;
            3) SELECTED_DE="kde"; break ;;
            4) SELECTED_DE="kali"; break ;;
            5) SELECTED_DE="hyprland"; break ;;
            6) SELECTED_DE="i3"; break ;;
            7) SELECTED_DE="cinnamon"; break ;;
            8) SELECTED_DE="mate"; break ;;
            9) SELECTED_DE="lxde"; break ;;
            10) SELECTED_DE="openbox"; break ;;
            *)
                print_error "Invalid choice. Please enter 1-10"
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
    
    if ! validate_desktop "$desktop"; then
        print_error "Invalid desktop environment: $desktop"
        exit 1
    fi

    IFS='|' read -r DESKTOP_NAME MAIN_PACKAGE EXTRA_PACKAGES STARTUP_CMD DESKTOP_SESSION SIZE <<< "$(get_desktop_info "$desktop")"
    print_status "Selected desktop environment: $DESKTOP_NAME"
    echo ""
    
    # Install base packages first
    install_base_packages
    
    # Set the global SELECTED_DE variable
    SELECTED_DE="$desktop"

    # Install desktop environment
    install_desktop_environment
    
    # Ensure all required packages are installed
    ensure_vnc_installed
    
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
                print_warning "This will install XFCE and a set of security tools."
                if [[ "$SELECTED_OS" != "arch" ]]; then
                    print_warning "Kali Linux requires ~1.5GB download"
                    echo -n "Install full Kali tool collection? (y/N): "
                    read -r tools_confirm
                    if [[ $tools_confirm =~ ^[Yy]$ ]]; then
                        KALI_TOOLS_ENABLED=true
                    fi
                fi
                echo -n "Continue with installation? (y/N): "
                read -r confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    start_desktop "kali"
                    break
                fi
                ;;
            5)
                start_desktop "hyprland"
                break
                ;;
            6)
                start_desktop "i3"
                break
                ;;
            7)
                start_desktop "cinnamon"
                break
                ;;
            8)
                start_desktop "mate"
                break
                ;;
            9)
                start_desktop "lxde"
                break
                ;;
            10)
                start_desktop "openbox"
                break
                ;;
            [qQ]|quit|exit)
                echo ""
                print_status "Goodbye!"
                exit 0
                ;;
            *)
                echo ""
                print_error "Invalid choice. Please enter 1-10, or 'q'"
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
        "dbus")
            check_dbus_status
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
        "kali-tools")
            if [[ "$SELECTED_OS" == "arch" ]]; then
                install_kali_tools_arch
            else
                install_kali_linux
            fi
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

# Pre-setup system check and preparation
prepare_system() {
    print_header "PREPARING SYSTEM"
    
    # Detect the actual OS
    if [ -f /etc/arch-release ]; then
        DETECTED_OS="arch"
    elif [ -f /etc/debian_version ]; then
        if grep -q "kali" /etc/os-release 2>/dev/null; then
            DETECTED_OS="kali"
        else
            DETECTED_OS="debian"
        fi
    elif [ -f /etc/lsb-release ]; then
        if grep -q "Ubuntu" /etc/lsb-release; then
            DETECTED_OS="ubuntu"
        else
            DETECTED_OS="debian"
        fi
    else
        DETECTED_OS="unknown"
    fi
    
    print_status "Detected OS: $DETECTED_OS"
    
    # Set SELECTED_OS if not already set
    if [[ -z "$SELECTED_OS" ]]; then
        SELECTED_OS="$DETECTED_OS"
    fi
    
    # Ensure essential packages are available
    case "$DETECTED_OS" in
        "arch")
            print_status "Ensuring package manager is ready..."
            sudo pacman -Sy --noconfirm
            
            # Install essential tools
            if ! command -v curl >/dev/null 2>&1; then
                sudo pacman -S --noconfirm curl
            fi
            if ! command -v wget >/dev/null 2>&1; then
                sudo pacman -S --noconfirm wget
            fi
            ;;
        *)
            print_status "Ensuring package manager is ready..."
            sudo apt update -qq
            
            # Install essential tools
            if ! command -v curl >/dev/null 2>&1; then
                safe_apt_install curl
            fi
            if ! command -v wget >/dev/null 2>&1; then
                safe_apt_install wget
            fi
            ;;
    esac
    
    print_success "System prepared for installation"
}

# Main Setup Function
comprehensive_setup() {
    print_banner
    echo ""
    print_header "COMPREHENSIVE SYSTEM SETUP"
    echo ""
    
    # Prepare system first
    prepare_system
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
    
    # Install base system first
    install_base_system
    
    # Install base packages (VNC, SSH, etc.)
    install_base_packages
    
    # Install desktop environment
    install_desktop_environment
    
    # Install connection methods
    install_connection_methods
    
    # Create user account
    create_user_account
    
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
    
    case "$SELECTED_OS" in
        "arch")
            print_warning "RDP server (xrdp) not fully available on Arch Linux"
            print_status "RDP configuration skipped for Arch Linux"
            ;;
        *)
            # Configure XRDP for Debian-based systems
            sudo sed -i "s/port=3389/port=$RDP_PORT/g" /etc/xrdp/xrdp.ini
            
            # Configure session for the user
            echo "exec startxfce4" | sudo -u "$USERNAME" tee "/home/$USERNAME/.xsession" > /dev/null
            
            # Fix XRDP session issues
            if [ -f /etc/X11/Xwrapper.config ]; then
                sudo sed -i 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config
            fi
            ;;
    esac
    
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
    
    # Create X11VNC password file for the user using a non-interactive method
    print_status "Creating X11VNC password file..."
    
    # Use printf to avoid interactive prompts
    printf "%s\n%s\n" "$PASSWORD" "$PASSWORD" | sudo -u "$USERNAME" x11vnc -storepasswd "/home/$USERNAME/.x11vnc_passwd" 2>/dev/null || {
        # Alternative method if x11vnc interactive fails
        print_status "Using alternative password creation method..."
        echo "$PASSWORD" | sudo -u "$USERNAME" openssl passwd -stdin | sudo -u "$USERNAME" tee "/home/$USERNAME/.x11vnc_passwd" > /dev/null
        sudo chmod 600 "/home/$USERNAME/.x11vnc_passwd"
        sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/.x11vnc_passwd"
    }
    
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
    
    # Ensure VNC is installed before trying to start
    if ! command -v vncserver >/dev/null 2>&1; then
        print_error "VNC server not found. Installing..."
        ensure_vnc_installed
    fi
    
    # Check if VNC password file exists, create if not
    if [ ! -f "/home/$USERNAME/.vnc/passwd" ]; then
        print_status "VNC password file not found, creating..."
        configure_vnc
    fi
    
    # Ensure xstartup script exists and is executable
    if [ ! -f "/home/$USERNAME/.vnc/xstartup" ] || [ ! -x "/home/$USERNAME/.vnc/xstartup" ]; then
        print_status "VNC startup script missing or not executable, recreating..."
        create_vnc_startup_script
        sudo chmod +x "/home/$USERNAME/.vnc/xstartup"
        sudo chown "$USERNAME:$USERNAME" "/home/$USERNAME/.vnc/xstartup"
    fi
    
    # Kill any existing VNC session first
    print_status "Stopping any existing VNC sessions..."
    sudo -u "$USERNAME" vncserver -kill "$VNC_DISPLAY" 2>/dev/null || true
    
    # Clean up any leftover files
    sudo rm -f "/home/$USERNAME/.vnc/*.pid" 2>/dev/null || true
    sudo rm -f "/tmp/.X*-lock" 2>/dev/null || true
    
    # Start VNC server as the created user with enhanced options
    print_status "Starting VNC server on display $VNC_DISPLAY..."
    sudo -u "$USERNAME" bash -c "
        cd /home/$USERNAME
        export HOME=/home/$USERNAME
        export USER=$USERNAME
        vncserver $VNC_DISPLAY -geometry $RESOLUTION -depth 24 -localhost no -SecurityTypes VncAuth
    " 2>/tmp/vnc_startup.log
    
    sleep 5
    
    if is_vnc_running; then
        print_success "VNC server started successfully on port $VNC_PORT"
    else
        print_fail "Failed to start VNC server"
        # Try to get more information about the failure
        print_status "Checking VNC startup log for errors..."
        if [ -f /tmp/vnc_startup.log ]; then
            print_status "VNC startup log:"
            cat /tmp/vnc_startup.log
        fi
        if [ -f "/home/$USERNAME/.vnc/"*"$VNC_DISPLAY.log" ]; then
            print_status "VNC session log (last 10 lines):"
            tail -10 "/home/$USERNAME/.vnc/"*"$VNC_DISPLAY.log" 2>/dev/null || true
        fi
        return 1
    fi
}

start_novnc_service() {
    print_status "Starting noVNC web interface..."
    
    # Find the correct noVNC path with multiple fallbacks
    local novnc_path=""
    local possible_paths=(
        "/usr/share/novnc"
        "/usr/share/novnc/web"
        "/usr/local/share/novnc"
        "/opt/novnc"
        "/usr/lib/novnc"
    )
    
    for path in "${possible_paths[@]}"; do
        if [ -d "$path" ] && [ -f "$path/vnc.html" -o -f "$path/vnc_lite.html" -o -f "$path/index.html" ]; then
            novnc_path="$path"
            print_status "Found noVNC at: $novnc_path"
            break
        fi
    done
    
    if [ -z "$novnc_path" ]; then
        print_error "noVNC web directory not found in any standard location"
        print_status "Attempted paths: ${possible_paths[*]}"
        return 1
    fi
    
    # Check if websockify command is available
    if ! command -v websockify >/dev/null 2>&1; then
        print_error "websockify command not found. Please ensure it's installed."
        print_status "For Arch: sudo pacman -S python-websockify"
        print_status "For Debian/Ubuntu: sudo apt install websockify"
        return 1
    fi
    
    # Kill any existing websockify process
    pkill -f "websockify.*$NOVNC_PORT" 2>/dev/null || true
    sleep 1
    
    print_status "Starting websockify with noVNC web path: $novnc_path"
    websockify --web="$novnc_path" "$NOVNC_PORT" "localhost:$VNC_PORT" > /tmp/websockify.log 2>&1 &
    sleep 3
    
    if is_websockify_running; then
        print_success "noVNC web server started successfully on port $NOVNC_PORT"
    else
        print_fail "Failed to start noVNC web server"
        print_status "Websockify log:"
        cat /tmp/websockify.log 2>/dev/null | tail -5 || true
    fi
}

start_rdp_service() {
    print_status "Starting RDP server..."
    
    case "$SELECTED_OS" in
        "arch")
            print_warning "RDP server (xrdp) not available on Arch Linux"
            print_status "RDP service start skipped for Arch Linux"
            ;;
        *)
            if command -v systemctl >/dev/null 2>&1; then
                sudo systemctl enable xrdp
                sudo systemctl start xrdp
            else
                sudo service xrdp start
            fi
            print_success "RDP server started"
            ;;
    esac
}

start_ssh_service() {
    print_status "Starting SSH server..."
    
    if command -v systemctl >/dev/null 2>&1; then
        if [[ "$SELECTED_OS" == "arch" ]]; then
            sudo systemctl enable sshd
            sudo systemctl start sshd
        else
            sudo systemctl enable ssh
            sudo systemctl start ssh
        fi
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
                if [[ "$SELECTED_OS" != "arch" ]]; then
                    echo -e "${GREEN}🖥️ RDP Connection:${NC}"
                    echo "   Server: $CODESPACE_NAME-$RDP_PORT.app.github.dev:$RDP_PORT"
                    echo "   Username: $USERNAME"
                    echo "   Password: [Your user password]"
                    echo ""
                else
                    echo -e "${YELLOW}⚠️ RDP Connection:${NC}"
                    echo "   RDP not available on Arch Linux"
                    echo ""
                fi
                ;;
            "ssh")
                echo -e "${GREEN}🔐 SSH Access:${NC}"
                echo "   ssh -p $SSH_PORT $USERNAME@$CODESPACE_NAME-$SSH_PORT.app.github.dev"
                ;;
            "x11vnc")
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
    # First try to stop VNC using the USERNAME if set
    if [[ -n "$USERNAME" ]]; then
        sudo -u "$USERNAME" vncserver -kill "$VNC_DISPLAY" 2>/dev/null || true
    fi
    
    # Also kill any running VNC processes (fallback)
    pkill -f "Xtigervnc.*:1" 2>/dev/null || true
    pkill -f "vncserver.*:1" 2>/dev/null || true
    
    print_status "Stopping noVNC..."
    pkill -f websockify 2>/dev/null || true
    
    print_status "Stopping X11VNC..."
    pkill -f x11vnc 2>/dev/null || true
    
    print_status "Stopping SSH server..."
    if command -v systemctl >/dev/null 2>&1; then
        if [[ "$SELECTED_OS" == "arch" ]]; then
            sudo systemctl stop sshd 2>/dev/null || true
        else
            sudo systemctl stop ssh 2>/dev/null || true
        fi
    else
        sudo service ssh stop 2>/dev/null || true
    fi
    
    print_status "Stopping RDP server..."
    case "$SELECTED_OS" in
        "arch")
            # RDP not available on Arch, skip
            ;;
        *)
            if command -v systemctl >/dev/null 2>&1; then
                sudo systemctl stop xrdp 2>/dev/null || true
            else
                sudo service xrdp stop 2>/dev/null || true
            fi
            ;;
    esac
    
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
    echo "  dbus         Check D-Bus service status and diagnostics"
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
    echo "  • Kali Tools  - Security tools with XFCE"
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
    echo "  $0 dbus               # Check D-Bus diagnostics"
    echo "  $0 start              # Start all configured services"
    echo "  $0 stop               # Stop all services"
    echo "  $0 kali-tools         # Install security tools"
    echo ""
    echo -e "${YELLOW}First Time Usage:${NC}"
    echo "  Run '$0' or '$0 setup' to start the interactive configuration wizard."
    echo "  The wizard will guide you through selecting your OS, desktop"
    echo "  environment, creating a user account, and configuring access methods."
    echo ""
}

# Execute main function with all command line arguments
main "$@"
