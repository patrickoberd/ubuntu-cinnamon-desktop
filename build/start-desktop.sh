#!/bin/bash
# Startup script for Ubuntu Cinnamon Desktop workspace
# Initializes VNC server, Cinnamon session, noVNC, code-server, and Coder agent

set -e

echo "Starting Ubuntu Cinnamon Desktop workspace..."

# ============================================================================
# PHASE 1: First-Run Configuration
# ============================================================================

if [ ! -f "$HOME/.workspace-initialized" ]; then
    echo "First run detected - initializing workspace..."

    # Copy default configs from /etc/skel if they don't exist
    for file in .oh-my-zsh .zshrc .tmux.conf .continue; do
        if [ ! -e "$HOME/$file" ]; then
            cp -r "/etc/skel/$file" "$HOME/$file"
            echo "Copied $file from skeleton"
        fi
    done

    # Create common directories
    mkdir -p "$HOME/Downloads" "$HOME/Pictures/screenshots" "$HOME/notes" "$HOME/projects"

    # Apply customizations from environment variables
    echo "Applying user customizations..."

    # Set default shell
    if [ "${DEFAULT_SHELL:-zsh}" = "bash" ]; then
        sudo chsh -s /bin/bash coder
    else
        sudo chsh -s /bin/zsh coder
    fi

    # Configure git
    git config --global init.defaultBranch "${GIT_DEFAULT_BRANCH:-main}"
    git config --global user.name "${GIT_AUTHOR_NAME:-Coder User}"
    git config --global user.email "${GIT_AUTHOR_EMAIL:-coder@localhost}"
    git config --global pull.rebase false

    # Create desktop launchers directory
    mkdir -p "$HOME/.local/share/applications"

    # Mark workspace as initialized
    touch "$HOME/.workspace-initialized"
    echo "Workspace initialization complete!"
fi

# ============================================================================
# PHASE 2: Display Setup
# ============================================================================

echo "Setting up X11 display..."

# Export display variable
export DISPLAY=:1

# Create runtime directory for X11
export XDG_RUNTIME_DIR=/tmp/runtime-coder
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Create VNC directory
mkdir -p "$HOME/.vnc"

# Parse resolution from parameter (default 1920x1080)
RESOLUTION="${DESKTOP_RESOLUTION:-1920x1080}"
echo "Desktop resolution: $RESOLUTION"

# Configure VNC server
cat > ~/.vnc/config << EOF
geometry=$RESOLUTION
depth=24
localhost=yes
alwaysshared=yes
securitytypes=none
EOF

echo "VNC configuration created"

# ============================================================================
# PHASE 3: Service Startup
# ============================================================================

echo "Starting desktop services..."

# Kill any existing services (idempotent restarts)
pkill -f "Xvnc" || true
pkill -f "cinnamon-session" || true
pkill -f "websockify" || true
pkill -f "code-server" || true
sleep 2

# Start Xvnc server
echo "Starting Xvnc server..."
Xvnc :1 -rfbport 5901 -SecurityTypes None -geometry $RESOLUTION -depth 24 -localhost yes -AlwaysShared yes > /tmp/xvnc.log 2>&1 &
XVNC_PID=$!
echo "Xvnc started with PID $XVNC_PID"

# Wait for X server to be ready
echo "Waiting for X server to be ready..."
for i in {1..30}; do
    if xdpyinfo -display :1 >/dev/null 2>&1; then
        echo "X server is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "ERROR: X server failed to start within 30 seconds"
        cat /tmp/xvnc.log
        exit 1
    fi
    sleep 1
done

# Set environment for X11 applications
export DISPLAY=:1
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

# Start D-Bus session bus
echo "Starting D-Bus session..."
mkdir -p /run/user/$(id -u)
if [ ! -S "/run/user/$(id -u)/bus" ]; then
    dbus-daemon --session --address="$DBUS_SESSION_BUS_ADDRESS" --nofork --nopidfile --syslog-only &
    DBUS_PID=$!
    sleep 2
    echo "D-Bus started with PID $DBUS_PID"
fi

# Start Cinnamon session
echo "Starting Cinnamon desktop environment..."
cinnamon-session > /tmp/cinnamon.log 2>&1 &
CINNAMON_PID=$!
echo "Cinnamon started with PID $CINNAMON_PID"

# Wait for Cinnamon to initialize
sleep 5

# Apply Cinnamon customizations via gsettings (if dconf is available)
if command -v gsettings &> /dev/null; then
    echo "Applying Cinnamon customizations..."

    # Set theme
    THEME="${CINNAMON_THEME:-Mint-Y-Dark}"
    gsettings set org.cinnamon.desktop.interface gtk-theme "$THEME" 2>/dev/null || true
    gsettings set org.cinnamon.theme name "$THEME" 2>/dev/null || true

    # Set panel position
    PANEL_POS="${PANEL_POSITION:-bottom}"
    # Note: Panel position changes require more complex dconf manipulation
    # For simplicity, we'll document this as a manual setting

    # Enable desktop icons
    gsettings set org.nemo.desktop show-desktop-icons true 2>/dev/null || true

    # Set favorite apps in panel
    gsettings set org.cinnamon favorite-apps "['gnome-terminal.desktop', 'firefox.desktop', 'nemo.desktop']" 2>/dev/null || true

    echo "Cinnamon customizations applied"
fi

# Auto-start applications if enabled
if [ "${AUTO_START_APPS:-true}" = "true" ]; then
    echo "Auto-starting applications..."
    sleep 3
    # Give Cinnamon time to fully load before launching apps
    firefox http://localhost:8080 > /dev/null 2>&1 &
    echo "Firefox launched"
fi

# Start noVNC websocket proxy
echo "Starting noVNC..."
/opt/websockify/run localhost:6080 localhost:5901 > /tmp/novnc.log 2>&1 &
NOVNC_PID=$!
echo "noVNC started with PID $NOVNC_PID"

# Start code-server
echo "Starting code-server..."
mkdir -p ~/.config/code-server
cat > ~/.config/code-server/config.yaml << 'CODECFG'
bind-addr: 0.0.0.0:8080
auth: none
cert: false
CODECFG

code-server --bind-addr 0.0.0.0:8080 > /tmp/code-server.log 2>&1 &
CODE_SERVER_PID=$!
echo "code-server started with PID $CODE_SERVER_PID"

# ============================================================================
# PHASE 4: Coder Agent Installation
# ============================================================================

echo "Installing Coder agent..."

if [ -n "${CODER_AGENT_TOKEN:-}" ]; then
    # Determine Coder server URL
    CODER_SERVER_URL="${CODER_AGENT_URL:-http://coder.coder.svc.cluster.local}"

    # Download Coder agent
    echo "Downloading Coder agent from $CODER_SERVER_URL..."
    if curl -fsSL "$CODER_SERVER_URL/bin/coder-linux-amd64" -o /tmp/coder; then
        chmod +x /tmp/coder

        # Start Coder agent
        echo "Starting Coder agent..."
        /tmp/coder agent > /tmp/coder-agent.log 2>&1 &
        CODER_AGENT_PID=$!
        echo "Coder agent started with PID $CODER_AGENT_PID"
    else
        echo "WARNING: Failed to download Coder agent from $CODER_SERVER_URL"
        echo "Workspace will function but Coder integration may be limited"
    fi
else
    echo "No CODER_AGENT_TOKEN provided - skipping Coder agent installation"
fi

# ============================================================================
# PHASE 5: Health Monitoring Loop
# ============================================================================

echo ""
echo "============================================"
echo "Ubuntu Cinnamon Desktop is ready!"
echo "============================================"
echo "Access via noVNC: http://localhost:6080"
echo "Access VS Code: http://localhost:8080"
echo "============================================"
echo ""

# Monitor processes and restart if they crash
monitor_process() {
    local pid=$1
    local name=$2
    local restart_cmd=$3

    if ! kill -0 $pid 2>/dev/null; then
        echo "WARNING: $name (PID $pid) has stopped. Restarting..."
        eval "$restart_cmd &"
        local new_pid=$!
        echo "$name restarted with new PID $new_pid"
        return $new_pid
    fi
    return $pid
}

# Trap SIGTERM for graceful shutdown
trap "echo 'Shutting down...'; exit 0" SIGTERM SIGINT

# Main monitoring loop
while true; do
    # Check Xvnc
    if [ -n "${XVNC_PID:-}" ]; then
        XVNC_PID=$(monitor_process $XVNC_PID "Xvnc" "Xvnc :1 -rfbport 5901 -SecurityTypes None -geometry $RESOLUTION -depth 24 -localhost yes -AlwaysShared yes > /tmp/xvnc.log 2>&1")
    fi

    # Check Cinnamon
    if [ -n "${CINNAMON_PID:-}" ]; then
        CINNAMON_PID=$(monitor_process $CINNAMON_PID "Cinnamon" "cinnamon-session > /tmp/cinnamon.log 2>&1")
    fi

    # Check noVNC
    if [ -n "${NOVNC_PID:-}" ]; then
        NOVNC_PID=$(monitor_process $NOVNC_PID "noVNC" "/opt/websockify/run localhost:6080 localhost:5901 > /tmp/novnc.log 2>&1")
    fi

    # Check code-server
    if [ -n "${CODE_SERVER_PID:-}" ]; then
        CODE_SERVER_PID=$(monitor_process $CODE_SERVER_PID "code-server" "code-server --bind-addr 0.0.0.0:8080 > /tmp/code-server.log 2>&1")
    fi

    # Check Coder agent
    if [ -n "${CODER_AGENT_PID:-}" ]; then
        CODER_AGENT_PID=$(monitor_process $CODER_AGENT_PID "Coder agent" "/tmp/coder agent > /tmp/coder-agent.log 2>&1")
    fi

    # Sleep before next check
    sleep 10
done
