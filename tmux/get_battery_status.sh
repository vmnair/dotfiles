#!/bin/bash

# Script to get battery status with dynamic icons for tmux status bar
# Shows appropriate icon based on power source and battery percentage

# Check if we're in a tmux session
if [ -z "$TMUX" ]; then
    exit 0
fi

# Get battery status with timeout and error handling
battery_info=$(timeout 2 pmset -g batt 2>/dev/null)

if [ -z "$battery_info" ]; then
    echo "N/A"
    exit 0
fi

# Extract percentage
percentage=$(echo "$battery_info" | grep -o '[0-9]*%' | head -1)

# Determine power source and charging state
if echo "$battery_info" | grep -q "AC Power"; then
    # On AC power
    if echo "$battery_info" | grep -q "not charging"; then
        # AC attached but not charging (full or maintenance mode)
        icon="■"
    elif echo "$battery_info" | grep -q "charging"; then
        # Actively charging
        icon="▲"
    else
        # AC attached, other state
        icon="■"
    fi
else
    # On battery power (discharging)
    icon="▼"
fi

# Output icon and percentage
if [ -n "$percentage" ]; then
    echo "${icon} ${percentage}"
else
    echo "${icon} N/A"
fi