#!/bin/bash
# Screenshot tool for Ubuntu Cinnamon Desktop
# Takes screenshots and copies them to clipboard

set -e

# Create screenshots directory
SCREENSHOT_DIR="$HOME/Pictures/screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Generate filename with timestamp
FILENAME="$SCREENSHOT_DIR/screenshot_$(date +%Y%m%d_%H%M%S).png"

# Determine screenshot mode
MODE="${1:-select}"

case "$MODE" in
    full)
        # Full screen screenshot
        maim "$FILENAME"
        RESULT="Full screen screenshot saved"
        ;;
    window)
        # Active window screenshot
        maim -i $(xdotool getactivewindow) "$FILENAME"
        RESULT="Window screenshot saved"
        ;;
    select|*)
        # Selection screenshot (default)
        maim -s "$FILENAME"
        RESULT="Screenshot saved"
        ;;
esac

# Copy to clipboard
xclip -selection clipboard -t image/png -i "$FILENAME"

# Show notification
if command -v notify-send &> /dev/null; then
    notify-send "Screenshot" "$RESULT: $FILENAME" -i "$FILENAME" -t 3000
fi

echo "$RESULT: $FILENAME"
