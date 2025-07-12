#!/bin/bash

# Ubuntu GUI Master Script - Complete Ubuntu Desktop with noVNC
# Supports XFCE, GNOME, and KDE desktop environments
# Author: GitHub Copilot Assistant
# Version: 2.0

set -e  # Exit on any error

# Configuration
DEFAULT_DESKTOP="xfce"
DESKTOP_ENV="${2:-$DEFAULT_DESKTOP}"
VNC_DISPLAY=":1"
VNC_PORT="5901"
NOVNC_PORT="6080"
RESOLUTION="1920x1080"

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
    echo "║                Ubuntu GUI Master Script                   ║"
    echo "║        Complete Desktop Environment with noVNC            ║"
    echo "║              XFCE • GNOME • KDE Support                   ║"
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

validate_desktop() {
    case "$1" in
        "xfce"|"gnome"|"kde")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

get_desktop_info() {
    case "$1" in
        "xfce")
            echo "XFCE|xfce4|xfce4-goodies|startxfce4|XFCE|200MB"
            ;;
        "gnome")
            echo "GNOME|gnome-shell|metacity|gnome-session|GNOME|800MB"
            ;;
        "kde")
            echo "KDE Plasma|kde-plasma-desktop|plasma-widgets-addons|startplasma-x11|KDE|1GB"
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
        print_status "Available options: xfce, gnome, kde"
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
    esac
    
    print_success "$DESKTOP_NAME desktop environment installed"
}

# Configuration functions
configure_vnc() {
    local desktop=$1
    
    print_header "CONFIGURING VNC FOR $desktop"
    
    IFS='|' read -r DESKTOP_NAME MAIN_PACKAGE EXTRA_PACKAGES STARTUP_CMD DESKTOP_SESSION SIZE <<< "$(get_desktop_info "$desktop")"
    
    mkdir -p ~/.vnc
    
    print_status "Creating VNC startup configuration for $DESKTOP_NAME..."
    
    case "$desktop" in
        "xfce")
            cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export DESKTOP_SESSION=xfce
export XDG_SESSION_TYPE=x11

[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid "#2E3440"

if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
    export DBUS_SESSION_BUS_ADDRESS
fi

exec startxfce4
EOF
            ;;
        "gnome")
            cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_DESKTOP=gnome
export DESKTOP_SESSION=gnome
export XDG_SESSION_TYPE=x11
export XDG_RUNTIME_DIR=/tmp/runtime-$USER
export LIBGL_ALWAYS_SOFTWARE=1

mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid "#3465a4"

if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
    export DBUS_SESSION_BUS_ADDRESS
fi

metacity &
sleep 2
gnome-shell --x11 --replace &
sleep 3
gnome-terminal &
nautilus --no-desktop &

exec tail -f /dev/null
EOF
            ;;
        "kde")
            cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_DESKTOP=KDE
export DESKTOP_SESSION=plasma
export XDG_SESSION_TYPE=x11
export KDE_FULL_SESSION=true

[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid "#1d99f3"

if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
    export DBUS_SESSION_BUS_ADDRESS
fi

exec startplasma-x11
EOF
            ;;
    esac
    
    chmod +x ~/.vnc/xstartup
    print_success "VNC configuration completed for $DESKTOP_NAME"
}

# Service management functions
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

stop_services() {
    print_header "STOPPING SERVICES"
    
    print_status "Stopping VNC server..."
    vncserver -kill $VNC_DISPLAY 2>/dev/null || true
    
    print_status "Stopping noVNC..."
    pkill -f websockify 2>/dev/null || true
    
    sleep 2
    print_success "All services stopped"
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
    
    if is_vnc_running && is_websockify_running; then
        echo ""
        print_header "ACCESS INFORMATION"
        echo -e "${CYAN}🌐 Access URL:${NC}"
        echo "   https://$CODESPACE_NAME-$NOVNC_PORT.app.github.dev/vnc.html"
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
    echo -e "${CYAN}📝 Usage Notes:${NC}"
    echo "   • Click 'Connect' in the noVNC interface"
    echo "   • Use your VNC password when prompted"
    echo "   • Desktop resolution: $RESOLUTION"
    echo "   • Desktop Environment: $DESKTOP_NAME"
    echo ""
    echo -e "${CYAN}🛠️ Management Commands:${NC}"
    echo "   • Stop: $0 stop"
    echo "   • Restart: $0 restart [$desktop]"
    echo "   • Status: $0 status"
    echo "   • Switch desktop: $0 start [xfce|gnome|kde]"
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
    esac
    echo ""
}

show_desktop_menu() {
    print_banner
    echo ""
    echo -e "${CYAN}Available Desktop Environments:${NC}"
    echo ""
    echo -e "${GREEN}[1] XFCE${NC}        - Lightweight and fast (Recommended)"
    echo "    • Low resource usage (~200MB)"
    echo "    • Traditional desktop layout"
    echo "    • Fast startup and response"
    echo ""
    echo -e "${GREEN}[2] GNOME${NC}       - Modern and feature-rich"
    echo "    • Modern interface design (~800MB)"
    echo "    • Rich application ecosystem"
    echo "    • Good accessibility features"
    echo ""
    echo -e "${GREEN}[3] KDE Plasma${NC}  - Highly customizable"
    echo "    • Beautiful and customizable (~1GB)"
    echo "    • Powerful applications"
    echo "    • Advanced desktop effects"
    echo ""
}

show_help() {
    print_banner
    echo ""
    echo "Ubuntu GUI Master Script - Complete Desktop Environment with noVNC"
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo "  $0 [COMMAND] [DESKTOP_ENV]"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo "  start        Start Ubuntu GUI (default command)"
    echo "  stop         Stop all services"
    echo "  restart      Restart all services"
    echo "  status       Show service status"
    echo "  install      Install desktop environment only"
    echo "  menu         Show desktop selection menu"
    echo "  help         Show this help message"
    echo ""
    echo -e "${CYAN}Desktop Environments:${NC}"
    echo "  xfce         XFCE Desktop (lightweight, ~200MB) - default"
    echo "  gnome        GNOME Desktop (modern, ~800MB)"
    echo "  kde          KDE Plasma Desktop (customizable, ~1GB)"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  $0                     # Start with XFCE (default)"
    echo "  $0 start xfce          # Start XFCE desktop"
    echo "  $0 start gnome         # Start GNOME desktop"
    echo "  $0 start kde           # Start KDE desktop"
    echo "  $0 restart gnome       # Switch to GNOME"
    echo "  $0 stop                # Stop all services"
    echo "  $0 status              # Check what's running"
    echo "  $0 menu                # Show desktop selection menu"
    echo ""
    echo -e "${YELLOW}Note:${NC} GNOME and KDE require larger downloads. XFCE is recommended for"
    echo "      faster setup and lower resource usage in cloud environments."
    echo ""
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
        echo -n "Choose desktop environment (1-3) or 'q' to quit: "
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
            [qQ]|quit|exit)
                echo ""
                print_status "Goodbye!"
                exit 0
                ;;
            *)
                echo ""
                print_error "Invalid choice. Please enter 1, 2, 3, or 'q'"
                echo ""
                ;;
        esac
    done
}

# Main script logic
main() {
    case "${1:-start}" in
        "start")
            start_desktop "$DESKTOP_ENV"
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            print_header "RESTARTING UBUNTU GUI SERVICES"
            IFS='|' read -r DESKTOP_NAME _ _ _ _ _ <<< "$(get_desktop_info "$DESKTOP_ENV")"
            print_status "Selected desktop environment: $DESKTOP_NAME"
            configure_vnc "$DESKTOP_ENV"
            stop_services
            sleep 2
            if start_vnc_server && start_novnc_server; then
                show_connection_info "$DESKTOP_ENV"
            else
                print_error "Failed to restart services"
                exit 1
            fi
            ;;
        "status")
            show_status
            ;;
        "install")
            install_base_packages
            install_desktop_environment "$DESKTOP_ENV"
            configure_vnc "$DESKTOP_ENV"
            print_success "Installation completed. Run '$0 start $DESKTOP_ENV' to start services."
            ;;
        "menu")
            interactive_menu
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

# Run main function with all arguments
main "$@"
