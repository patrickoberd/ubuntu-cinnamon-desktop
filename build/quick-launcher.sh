#!/bin/bash
# Quick launcher menu for Ubuntu XFCE Desktop
# Provides quick access to common actions via rofi

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    echo "Error: rofi is not installed"
    exit 1
fi

# Menu options
OPTIONS="🖥️ Terminal
🌐 Firefox
📁 File Manager
📝 VS Code (browser)
📊 System Monitor
🧮 Calculator
📸 Screenshot (Full Screen)
📸 Screenshot (Select Area)
📸 Screenshot (Window)
📁 File Server (Toggle)
📝 Quick Note
📚 Browse Notes
🔒 Lock Screen
🔄 Reload Desktop
🚪 Log Out"

# Show menu and get selection
SELECTED=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Quick Actions" -theme Arc-Dark)

# Execute selected action
case "$SELECTED" in
    *"Terminal")
        xfce4-terminal &
        ;;
    *"Firefox")
        firefox &
        ;;
    *"File Manager")
        thunar &
        ;;
    *"VS Code"*)
        firefox http://localhost:8080 &
        ;;
    *"System Monitor")
        xfce4-terminal -e htop &
        ;;
    *"Calculator")
        galculator &
        ;;
    *"Screenshot (Full Screen)")
        /usr/local/bin/screenshot.sh full
        ;;
    *"Screenshot (Select Area)")
        /usr/local/bin/screenshot.sh select
        ;;
    *"Screenshot (Window)")
        /usr/local/bin/screenshot.sh window
        ;;
    *"File Server"*)
        /usr/local/bin/file-server.sh toggle
        ;;
    *"Quick Note")
        # Create note with timestamp
        NOTE_FILE="$HOME/notes/$(date +%Y-%m-%d).md"
        mkdir -p "$HOME/notes"

        # If note doesn't exist, add header
        if [ ! -f "$NOTE_FILE" ]; then
            echo "# Notes for $(date +%Y-%m-%d)" > "$NOTE_FILE"
            echo "" >> "$NOTE_FILE"
        fi

        # Open in text editor
        mousepad "$NOTE_FILE" &
        ;;
    *"Browse Notes")
        thunar "$HOME/notes" &
        ;;
    *"Lock Screen")
        xflock4
        ;;
    *"Reload Desktop")
        xfce4-panel --restart &
        xfwm4 --replace &
        ;;
    *"Log Out")
        xfce4-session-logout --logout
        ;;
esac
