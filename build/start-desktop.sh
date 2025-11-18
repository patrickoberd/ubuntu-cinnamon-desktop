#!/bin/bash
# Startup script for Ubuntu XFCE Desktop workspace
# Initializes VNC server, XFCE session, noVNC, code-server, and Coder agent

set -e

echo "Starting Ubuntu XFCE Desktop workspace..."

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

    # Note: Default shell is set in Dockerfile (zsh by default)
    # Users can manually change shell with: chsh -s /bin/bash (requires authentication)
    # The DEFAULT_SHELL env var is available for scripts but doesn't change login shell

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
pkill -f "xfce4-session" || true
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
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

# Start D-Bus session bus
echo "Starting D-Bus session..."
if [ ! -S "$XDG_RUNTIME_DIR/bus" ]; then
    dbus-daemon --session --address="$DBUS_SESSION_BUS_ADDRESS" --nofork --nopidfile --syslog-only &
    DBUS_PID=$!
    sleep 2
    echo "D-Bus started with PID $DBUS_PID"
fi

# Start XFCE session
echo "Starting XFCE desktop environment..."
startxfce4 > /tmp/xfce.log 2>&1 &
XFCE_PID=$!
echo "XFCE started with PID $XFCE_PID"

# Wait for XFCE to initialize
sleep 5

# Apply XFCE customizations via xfconf-query
if command -v xfconf-query &> /dev/null; then
    echo "Applying XFCE theme customizations..."

    # Wait for xfconf daemon
    for i in {1..30}; do
        if xfconf-query -c xsettings -l &>/dev/null; then
            break
        fi
        sleep 0.5
    done

    # Set Arc-Dark theme
    xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark" 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark" 2>/dev/null || true
    xfconf-query -c xsettings -p /Gtk/FontName -s "Ubuntu 11" 2>/dev/null || true

    # Panel configuration
    xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=8;x=0;y=0" 2>/dev/null || true
    xfconf-query -c xfce4-panel -p /panels/panel-1/size -s 32 2>/dev/null || true

    echo "XFCE customizations applied"
fi

# Start noVNC websocket proxy
echo "Starting noVNC..."
/opt/websockify/run --web /opt/noVNC localhost:6080 localhost:5901 > /tmp/novnc.log 2>&1 &
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

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 3

# Verify critical services are running
for service_port in "5901:VNC" "6080:noVNC" "8080:code-server"; do
    port="${service_port%%:*}"
    name="${service_port##*:}"
    if ! timeout 30 bash -c "until nc -z localhost $port 2>/dev/null; do sleep 1; done" 2>/dev/null; then
        echo "WARNING: $name (port $port) is not responding"
    else
        echo "$name is ready on port $port"
    fi
done

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
echo "Ubuntu XFCE Desktop is ready!"
echo "============================================"
echo "Access via noVNC: http://localhost:6080"
echo "Access VS Code: http://localhost:8080"
echo "Theme: Arc-Dark with Papirus icons"
echo "============================================"
echo ""

# Monitor processes and restart if they crash
monitor_process() {
    local pid=$1
    local name=$2
    local restart_cmd=$3

    if ! kill -0 $pid 2>/dev/null; then
        echo "WARNING: $name (PID $pid) has stopped. Restarting..." >&2
        eval "$restart_cmd &"
        local new_pid=$!
        echo "$name restarted with new PID $new_pid" >&2
        echo $new_pid
    else
        echo $pid
    fi
}

# Trap SIGTERM for graceful shutdown
trap "echo 'Shutting down...'; exit 0" SIGTERM SIGINT

# Main monitoring loop
while true; do
    # Check Xvnc
    if [ -n "${XVNC_PID:-}" ]; then
        XVNC_PID=$(monitor_process $XVNC_PID "Xvnc" "Xvnc :1 -rfbport 5901 -SecurityTypes None -geometry $RESOLUTION -depth 24 -localhost yes -AlwaysShared yes > /tmp/xvnc.log 2>&1")
    fi

    # Check XFCE
    if [ -n "${XFCE_PID:-}" ]; then
        XFCE_PID=$(monitor_process $XFCE_PID "XFCE" "startxfce4 > /tmp/xfce.log 2>&1")
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
