#!/bin/bash

# Manual test of VNC and noVNC setup to verify the fixes work in practice
set -e

echo "=== MANUAL VNC SETUP TEST ==="
echo "Testing the actual VNC and noVNC functionality with the applied fixes"
echo ""

cd /home/runner/work/Codespcaes_gui/Codespcaes_gui

# Variables
TEST_USER="vnctestuser"
TEST_PASS="testpass123"
VNC_DISPLAY=":1"
VNC_PORT="5901"
NOVNC_PORT="6080"
RESOLUTION="1920x1080"

echo "[STEP 1] Setting up test user..."
if ! id "$TEST_USER" &>/dev/null; then
    sudo useradd -m -s /bin/bash "$TEST_USER"
    echo "$TEST_USER:$TEST_PASS" | sudo chpasswd
    sudo usermod -aG sudo "$TEST_USER"
    echo "✓ Created test user: $TEST_USER"
else
    echo "✓ Test user already exists: $TEST_USER"
fi

echo ""
echo "[STEP 2] Creating VNC directories and password..."
sudo -u "$TEST_USER" mkdir -p "/home/$TEST_USER/.vnc"
echo "$TEST_PASS" | sudo -u "$TEST_USER" vncpasswd -f > "/tmp/vncpass.tmp"
sudo mv "/tmp/vncpass.tmp" "/home/$TEST_USER/.vnc/passwd"
sudo chmod 600 "/home/$TEST_USER/.vnc/passwd"
sudo chown "$TEST_USER:$TEST_USER" "/home/$TEST_USER/.vnc/passwd"
echo "✓ VNC password configured"

echo ""
echo "[STEP 3] Creating improved VNC startup script..."
# Create the improved startup script with all our fixes
sudo -u "$TEST_USER" tee "/home/$TEST_USER/.vnc/xstartup" > /dev/null << 'EOF'
#!/bin/bash
export XKL_XMODMAP_DISABLE=1
export XDG_SESSION_TYPE=x11
export HOME=/home/vnctestuser
export USER=vnctestuser

# Source system defaults - with error handling (our fix)
[ -r /etc/X11/Xresources ] && xrdb /etc/X11/Xresources 2>/dev/null || true
[ -d /etc/X11/Xresources ] && [ -f /etc/X11/Xresources/x11-common ] && xrdb /etc/X11/Xresources/x11-common 2>/dev/null || true
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources 2>/dev/null || true

# Enhanced D-Bus session setup (our fix)
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    if command -v dbus-launch >/dev/null 2>&1; then
        eval $(dbus-launch --sh-syntax 2>/dev/null) && export DBUS_SESSION_BUS_ADDRESS || {
            export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-session-$USER-$$"
            if command -v dbus-daemon >/dev/null 2>&1; then
                dbus-daemon --session --address="$DBUS_SESSION_BUS_ADDRESS" --nofork --nopidfile --syslog-only 2>/dev/null &
                sleep 2
            fi
        }
    fi
fi

# Set XDG environment
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CACHE_HOME=$HOME/.cache
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export DESKTOP_SESSION=xfce

# Create necessary directories
mkdir -p $HOME/.config $HOME/.local/share $HOME/.cache

# Start XFCE
xsetroot -solid "#2E3440"
exec startxfce4
EOF

sudo chmod +x "/home/$TEST_USER/.vnc/xstartup"
sudo chown "$TEST_USER:$TEST_USER" "/home/$TEST_USER/.vnc/xstartup"
echo "✓ Enhanced VNC startup script created"

echo ""
echo "[STEP 4] Ensure /etc/X11/Xresources exists (our fix)..."
if [ ! -f /etc/X11/Xresources ] && [ ! -d /etc/X11/Xresources ]; then
    sudo mkdir -p /etc/X11
    sudo tee /etc/X11/Xresources > /dev/null << 'XRES_EOF'
! X11 Resources file
! Basic X11 settings  
*customization: -color
XRES_EOF
    echo "✓ Created missing /etc/X11/Xresources file"
elif [ -d /etc/X11/Xresources ]; then
    echo "✓ /etc/X11/Xresources directory already exists (system configured)"
else
    echo "✓ /etc/X11/Xresources file already exists"
fi

echo ""
echo "[STEP 5] Starting VNC server..."
sudo -u "$TEST_USER" bash -c "
    cd /home/$TEST_USER
    export HOME=/home/$TEST_USER
    export USER=$TEST_USER
    vncserver $VNC_DISPLAY -geometry $RESOLUTION -depth 24 -localhost no -SecurityTypes VncAuth
" 2>/tmp/vnc_manual_test.log

sleep 5

if pgrep -f "Xtigervnc.*$VNC_DISPLAY" > /dev/null 2>&1; then
    echo "✅ VNC server started successfully"
    VNC_SUCCESS=true
else
    echo "❌ VNC server failed to start"
    echo "VNC log:"
    cat /tmp/vnc_manual_test.log 2>/dev/null || true
    VNC_SUCCESS=false
fi

echo ""
echo "[STEP 6] Finding noVNC web directory (our improved detection)..."
NOVNC_PATH=""
POSSIBLE_PATHS=(
    "/usr/share/novnc"
    "/usr/share/novnc/web"
    "/usr/local/share/novnc"
    "/opt/novnc"
    "/usr/lib/novnc"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ] && [ -f "$path/vnc.html" -o -f "$path/vnc_lite.html" -o -f "$path/index.html" ]; then
        NOVNC_PATH="$path"
        echo "✓ Found noVNC at: $NOVNC_PATH"
        break
    fi
done

if [ -z "$NOVNC_PATH" ]; then
    echo "❌ noVNC web directory not found"
    NOVNC_SUCCESS=false
else
    echo ""
    echo "[STEP 7] Starting noVNC web interface..."
    if command -v websockify >/dev/null 2>&1; then
        websockify --web="$NOVNC_PATH" "$NOVNC_PORT" "localhost:$VNC_PORT" > /tmp/websockify_manual_test.log 2>&1 &
        sleep 3
        
        if pgrep -f "websockify.*$NOVNC_PORT" > /dev/null 2>&1; then
            echo "✅ noVNC web interface started successfully"
            NOVNC_SUCCESS=true
        else
            echo "❌ noVNC web interface failed to start"
            echo "Websockify log:"
            cat /tmp/websockify_manual_test.log 2>/dev/null || true
            NOVNC_SUCCESS=false
        fi
    else
        echo "❌ websockify command not found"
        NOVNC_SUCCESS=false
    fi
fi

echo ""
echo "[STEP 8] Testing connectivity..."
if [ "$VNC_SUCCESS" = true ]; then
    if netstat -tlnp | grep -q ":$VNC_PORT.*LISTEN"; then
        echo "✅ VNC port $VNC_PORT is listening"
    else
        echo "❌ VNC port $VNC_PORT is not listening"
    fi
fi

if [ "$NOVNC_SUCCESS" = true ]; then
    if netstat -tlnp | grep -q ":$NOVNC_PORT.*LISTEN"; then
        echo "✅ noVNC port $NOVNC_PORT is listening"
        
        if curl -s -I "http://localhost:$NOVNC_PORT" | grep -q "200 OK"; then
            echo "✅ noVNC web interface responds to HTTP requests"
            HTTP_SUCCESS=true
        else
            echo "❌ noVNC web interface does not respond properly"
            HTTP_SUCCESS=false
        fi
    else
        echo "❌ noVNC port $NOVNC_PORT is not listening"
        HTTP_SUCCESS=false
    fi
fi

echo ""
echo "=== TEST RESULTS ==="
if [ "$VNC_SUCCESS" = true ] && [ "$NOVNC_SUCCESS" = true ] && [ "$HTTP_SUCCESS" = true ]; then
    echo "🎉 SUCCESS: All components are working!"
    echo ""
    echo "🌐 Access URLs (if this were in a Codespace):"
    echo "   noVNC Web: https://[codespace-name]-6080.app.github.dev/vnc.html"
    echo "   VNC Client: [codespace-name]-5901.app.github.dev:5901"
    echo ""
    echo "🔧 Fixes that were applied and tested:"
    echo "   ✅ X11 resources file creation (prevents compilation errors)"
    echo "   ✅ Enhanced D-Bus session setup (prevents desktop component failures)"
    echo "   ✅ Improved noVNC path detection (prevents path not found errors)"
    echo "   ✅ Robust VNC startup with error handling"
    echo ""
    echo "These fixes should resolve the original issues:"
    echo "   • Arch: NoVNC 'Failed to connect to server' errors"
    echo "   • Debian: Package installation dpkg-divert conflicts"
else
    echo "❌ PARTIAL SUCCESS: Some components failed"
    echo "   VNC Server: $([ "$VNC_SUCCESS" = true ] && echo "✅ Working" || echo "❌ Failed")"
    echo "   noVNC Web: $([ "$NOVNC_SUCCESS" = true ] && echo "✅ Working" || echo "❌ Failed")"
    echo "   HTTP Response: $([ "$HTTP_SUCCESS" = true ] && echo "✅ Working" || echo "❌ Failed")"
fi

echo ""
echo "[CLEANUP] Stopping test services..."
sudo -u "$TEST_USER" vncserver -kill "$VNC_DISPLAY" 2>/dev/null || true
pkill -f "websockify.*$NOVNC_PORT" 2>/dev/null || true
echo "✓ Test services stopped"

echo ""
echo "Manual test completed."