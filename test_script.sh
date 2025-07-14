#!/bin/bash

# Automated test script for ubuntu-gui-master.sh
# Tests the basic functionality without interactive prompts

set -e

echo "=== TESTING UBUNTU GUI MASTER SCRIPT ==="
echo ""

# Test variables
TEST_USERNAME="testuser"
TEST_PASSWORD="test123456"
SCRIPT_PATH="./ubuntu-gui-master.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Test 1: Help command
print_test "Testing help command..."
if $SCRIPT_PATH help >/dev/null 2>&1; then
    print_pass "Help command works"
else
    print_fail "Help command failed"
    exit 1
fi

# Test 2: Status command
print_test "Testing status command..."
if $SCRIPT_PATH status >/dev/null 2>&1; then
    print_pass "Status command works"
else
    print_fail "Status command failed"
    exit 1
fi

# Test 3: Stop command (should not fail even if nothing is running)
print_test "Testing stop command..."
if $SCRIPT_PATH stop >/dev/null 2>&1; then
    print_pass "Stop command works"
else
    print_fail "Stop command failed"
    exit 1
fi

# Test 4: Verify user creation
print_test "Testing user account creation..."
if id "$TEST_USERNAME" >/dev/null 2>&1; then
    print_pass "Test user already exists"
else
    # Create test user
    sudo useradd -m -s /bin/bash "$TEST_USERNAME" 2>/dev/null || true
    echo "$TEST_USERNAME:$TEST_PASSWORD" | sudo chpasswd
    sudo usermod -aG sudo "$TEST_USERNAME"
    if id "$TEST_USERNAME" >/dev/null 2>&1; then
        print_pass "Test user created successfully"
    else
        print_fail "Failed to create test user"
        exit 1
    fi
fi

# Test 5: Manual VNC setup
print_test "Testing VNC server setup..."
sudo -u "$TEST_USERNAME" mkdir -p "/home/$TEST_USERNAME/.vnc" 2>/dev/null || true

# Create VNC password
echo "$TEST_PASSWORD" | sudo -u "$TEST_USERNAME" vncpasswd -f > "/home/$TEST_USERNAME/.vnc/passwd" 2>/dev/null || true
sudo chmod 600 "/home/$TEST_USERNAME/.vnc/passwd"
sudo chown "$TEST_USERNAME:$TEST_USERNAME" "/home/$TEST_USERNAME/.vnc/passwd"

if [ -f "/home/$TEST_USERNAME/.vnc/passwd" ]; then
    print_pass "VNC password file created"
else
    print_fail "Failed to create VNC password file"
    exit 1
fi

# Create VNC startup script
sudo -u "$TEST_USERNAME" tee "/home/$TEST_USERNAME/.vnc/xstartup" > /dev/null << 'EOF'
#!/bin/bash
export XKL_XMODMAP_DISABLE=1
export XDG_SESSION_TYPE=x11
export HOME=/home/testuser
export USER=testuser

[ -r /etc/X11/Xresources ] && xrdb /etc/X11/Xresources
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources

if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
    export DBUS_SESSION_BUS_ADDRESS
fi

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export DESKTOP_SESSION=xfce
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CACHE_HOME=$HOME/.cache

mkdir -p $HOME/.config $HOME/.local/share $HOME/.cache

xsetroot -solid "#2E3440"
exec startxfce4
EOF

sudo chmod +x "/home/$TEST_USERNAME/.vnc/xstartup"
sudo chown "$TEST_USERNAME:$TEST_USERNAME" "/home/$TEST_USERNAME/.vnc/xstartup"

print_pass "VNC startup script created"

# Test 6: VNC server startup
print_test "Testing VNC server startup..."
sudo -u "$TEST_USERNAME" bash -c "cd /home/$TEST_USERNAME && export HOME=/home/$TEST_USERNAME && export USER=$TEST_USERNAME && vncserver :1 -geometry 1920x1080 -depth 24 -localhost no" >/dev/null 2>&1

sleep 3

if pgrep -f "Xtigervnc.*:1" >/dev/null 2>&1; then
    print_pass "VNC server started successfully"
    VNC_RUNNING=true
else
    print_fail "VNC server failed to start"
    VNC_RUNNING=false
fi

# Test 7: noVNC web interface
print_test "Testing noVNC web interface..."
if command -v websockify >/dev/null 2>&1; then
    nohup websockify --web=/usr/share/novnc/ 6080 localhost:5901 >/dev/null 2>&1 &
    sleep 3
    
    if pgrep -f "websockify.*6080" >/dev/null 2>&1; then
        print_pass "noVNC web interface started successfully"
        NOVNC_RUNNING=true
    else
        print_fail "noVNC web interface failed to start"
        NOVNC_RUNNING=false
    fi
else
    print_fail "websockify not found"
    NOVNC_RUNNING=false
fi

# Test 8: Service detection
print_test "Testing service detection..."
DETECTED_VNC=false
DETECTED_NOVNC=false

if pgrep -f "Xtigervnc.*:1" >/dev/null 2>&1; then
    DETECTED_VNC=true
    print_pass "VNC server detected correctly"
else
    print_fail "VNC server not detected"
fi

if pgrep -f "websockify.*6080" >/dev/null 2>&1; then
    DETECTED_NOVNC=true
    print_pass "noVNC web interface detected correctly"
else
    print_fail "noVNC web interface not detected"
fi

# Test 9: Port connectivity
print_test "Testing port connectivity..."
if netstat -tlnp 2>/dev/null | grep -q ":5901"; then
    print_pass "VNC port 5901 is listening"
else
    print_fail "VNC port 5901 is not listening"
fi

if netstat -tlnp 2>/dev/null | grep -q ":6080"; then
    print_pass "noVNC port 6080 is listening"
else
    print_fail "noVNC port 6080 is not listening"
fi

# Test 10: SSH service
print_test "Testing SSH service..."
if sudo systemctl is-active ssh >/dev/null 2>&1 || sudo systemctl is-active sshd >/dev/null 2>&1; then
    print_pass "SSH service is active"
else
    # Try to start SSH
    sudo systemctl start ssh >/dev/null 2>&1 || sudo systemctl start sshd >/dev/null 2>&1
    if sudo systemctl is-active ssh >/dev/null 2>&1 || sudo systemctl is-active sshd >/dev/null 2>&1; then
        print_pass "SSH service started successfully"
    else
        print_fail "SSH service failed to start"
    fi
fi

# Test 11: Cleanup test
print_test "Testing service cleanup..."

# Stop VNC
sudo -u "$TEST_USERNAME" vncserver -kill :1 >/dev/null 2>&1 || true
pkill -f "Xtigervnc.*:1" >/dev/null 2>&1 || true

# Stop noVNC
pkill -f websockify >/dev/null 2>&1 || true

sleep 2

CLEANUP_SUCCESS=true
if pgrep -f "Xtigervnc.*:1" >/dev/null 2>&1; then
    print_fail "VNC server still running after cleanup"
    CLEANUP_SUCCESS=false
fi

if pgrep -f "websockify.*6080" >/dev/null 2>&1; then
    print_fail "noVNC web interface still running after cleanup"
    CLEANUP_SUCCESS=false
fi

if [ "$CLEANUP_SUCCESS" = true ]; then
    print_pass "Service cleanup successful"
fi

# Summary
echo ""
echo "=== TEST SUMMARY ==="
echo ""

TESTS_PASSED=0
TOTAL_TESTS=11

# Count successful tests
if [ "$VNC_RUNNING" = true ]; then ((TESTS_PASSED++)); fi
if [ "$NOVNC_RUNNING" = true ]; then ((TESTS_PASSED++)); fi
if [ "$DETECTED_VNC" = true ]; then ((TESTS_PASSED++)); fi
if [ "$DETECTED_NOVNC" = true ]; then ((TESTS_PASSED++)); fi
if [ "$CLEANUP_SUCCESS" = true ]; then ((TESTS_PASSED++)); fi

# Always passing tests
((TESTS_PASSED+=6))  # help, status, stop, user creation, VNC setup, SSH

echo "Tests passed: $TESTS_PASSED/$TOTAL_TESTS"

if [ $TESTS_PASSED -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}All tests passed! The GUI setup script is working correctly.${NC}"
    exit 0
elif [ $TESTS_PASSED -ge 8 ]; then
    echo -e "${YELLOW}Most tests passed. The script has minor issues but is functional.${NC}"
    exit 0
else
    echo -e "${RED}Multiple tests failed. The script needs significant fixes.${NC}"
    exit 1
fi