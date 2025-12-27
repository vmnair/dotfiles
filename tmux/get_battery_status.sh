#!/bin/bash

# Script to get battery status with Nerd Font icons for tmux status bar
# Uses Nerd Font battery glyphs with level indication
# Color: red <20%, yellow <50%, white otherwise
# Backup: get_battery_status.sh.backup (original version)

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

# Extract percentage (remove % sign for comparison)
percentage_raw=$(echo "$battery_info" | grep -o '[0-9]*%' | head -1)
percentage_num=$(echo "$percentage_raw" | sed 's/%//')

# Nerd Font battery icons (charging)
# 󰢟 󰢜 󰂆 󰂇 󰂈 󰢝 󰂉 󰢞 󰂊 󰂋 󰂅
# Nerd Font battery icons (discharging)
# 󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹

# Determine icon based on battery level and charging state
is_charging=false
if echo "$battery_info" | grep -q "AC Power"; then
    if echo "$battery_info" | grep -q "charging"; then
        is_charging=true
    fi
fi

# Select icon based on percentage level
if [ -n "$percentage_num" ]; then
    if $is_charging; then
        # Charging icons
        if [ "$percentage_num" -ge 90 ]; then
            icon="󰂅"
        elif [ "$percentage_num" -ge 80 ]; then
            icon="󰂋"
        elif [ "$percentage_num" -ge 70 ]; then
            icon="󰂊"
        elif [ "$percentage_num" -ge 60 ]; then
            icon="󰢞"
        elif [ "$percentage_num" -ge 50 ]; then
            icon="󰂉"
        elif [ "$percentage_num" -ge 40 ]; then
            icon="󰢝"
        elif [ "$percentage_num" -ge 30 ]; then
            icon="󰂈"
        elif [ "$percentage_num" -ge 20 ]; then
            icon="󰂇"
        elif [ "$percentage_num" -ge 10 ]; then
            icon="󰂆"
        else
            icon="󰢜"
        fi
    else
        # Discharging/AC icons
        if [ "$percentage_num" -ge 90 ]; then
            icon="󰁹"
        elif [ "$percentage_num" -ge 80 ]; then
            icon="󰂂"
        elif [ "$percentage_num" -ge 70 ]; then
            icon="󰂁"
        elif [ "$percentage_num" -ge 60 ]; then
            icon="󰂀"
        elif [ "$percentage_num" -ge 50 ]; then
            icon="󰁿"
        elif [ "$percentage_num" -ge 40 ]; then
            icon="󰁾"
        elif [ "$percentage_num" -ge 30 ]; then
            icon="󰁽"
        elif [ "$percentage_num" -ge 20 ]; then
            icon="󰁼"
        elif [ "$percentage_num" -ge 10 ]; then
            icon="󰁻"
        else
            icon="󰂎"
        fi
    fi

    # Apply color: red <20%, yellow <50%, white otherwise
    if [ "$percentage_num" -lt 20 ]; then
        echo "#[fg=red]${icon} ${percentage_raw}#[fg=white]"
    elif [ "$percentage_num" -lt 50 ]; then
        echo "#[fg=yellow]${icon} ${percentage_raw}#[fg=white]"
    else
        echo "${icon} ${percentage_raw}"
    fi
else
    echo "󰂑 N/A"
fi