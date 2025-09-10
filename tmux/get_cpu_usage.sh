#!/bin/bash

# Script to get CPU usage percentage with color coding for tmux status bar
# Colors: ≥30% yellow, ≥80% red, otherwise white
# Returns fixed-width format like " 12.3%"

# Check if we're in a tmux session
if [ -z "$TMUX" ]; then
    exit 0
fi

# Get CPU usage with timeout and error handling
cpu_usage=$(timeout 2 sh -c "top -l 1 | grep 'CPU usage' | awk '{print \$3}' | sed 's/,//' | sed 's/%//'" 2>/dev/null)

if [ -n "$cpu_usage" ] && [ "$cpu_usage" != "" ]; then
    # Format with single decimal precision
    formatted_cpu=$(printf "%.1f%%" "$cpu_usage")
    
    # Apply color coding based on thresholds
    cpu_int=$(printf "%.0f" "$cpu_usage")
    if [ "$cpu_int" -ge 80 ]; then
        echo "#[fg=red]${formatted_cpu}#[fg=white]"
    elif [ "$cpu_int" -ge 30 ]; then
        echo "#[fg=yellow]${formatted_cpu}#[fg=white]"
    else
        echo "${formatted_cpu}"
    fi
else
    echo "N/A%"
fi