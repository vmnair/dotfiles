#!/bin/bash

# Script to get WiFi status with VPN indicator for tmux status bar
# Uses macOS system_profiler for WiFi info (works on Apple Silicon)
# Icons: 󰖪 (off), 󰖩 (WiFi only), 󰖩󰦝 (WiFi + VPN)
# Color: red (weak), yellow (fair), white (good/excellent)

# Check if we're in a tmux session
if [ -z "$TMUX" ]; then
    exit 0
fi

# Check if WiFi is enabled
wifi_power=$(networksetup -getairportpower en0 2>/dev/null | awk '{print $4}')

if [ "$wifi_power" != "On" ]; then
    echo "#[fg=red]󰖪#[fg=white]"
    exit 0
fi

# Get WiFi info from system_profiler (more reliable on modern macOS)
wifi_info=$(system_profiler SPAirPortDataType 2>/dev/null)

# Check if connected
if ! echo "$wifi_info" | grep -q "Status: Connected"; then
    echo "#[fg=red]󰖪#[fg=white]"
    exit 0
fi

# Check if VPN is actively routing (default route through utun)
vpn_active=false
default_route=$(netstat -rn 2>/dev/null | grep -E "^(default|0\.0\.0\.0)" | awk '{print $4}' | head -1)
if echo "$default_route" | grep -q "^utun"; then
    vpn_active=true
fi

# Get signal strength (first "Signal / Noise" line after "Current Network")
# Format: "              Signal / Noise: -48 dBm / -97 dBm"
signal_line=$(echo "$wifi_info" | grep -A 10 "Current Network Information:" | grep "Signal / Noise:" | head -1)
rssi=$(echo "$signal_line" | sed 's/.*Signal \/ Noise: //' | awk '{print $1}')

# Choose icon based on VPN status
if $vpn_active; then
    icon="󰖩󰦝"  # WiFi + VPN shield
else
    icon="󰖩"   # WiFi only
fi

# Convert RSSI to color
# RSSI ranges: ≥-60 (good), -60 to -70 (fair), <-70 (weak)
if [ -n "$rssi" ] && [ "$rssi" -eq "$rssi" ] 2>/dev/null; then
    if [ "$rssi" -ge -60 ]; then
        # Good signal - white
        color=""
    elif [ "$rssi" -ge -70 ]; then
        # Fair signal - yellow
        color="#[fg=yellow]"
    else
        # Weak signal - red
        color="#[fg=red]"
    fi
else
    # Couldn't get RSSI, assume good
    color=""
fi

# Output icon with color
echo "${color}${icon}#[fg=white]"
