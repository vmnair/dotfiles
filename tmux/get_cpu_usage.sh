#!/bin/bash

# Script to get CPU usage percentage for tmux status bar
# Returns fixed-width format like " 12.3%"

# Check if we're in a tmux session
if [ -z "$TMUX" ]; then
    exit 0
fi

# Get CPU usage with timeout and error handling
cpu_usage=$(timeout 2 sh -c "top -l 1 | grep 'CPU usage' | awk '{print \$3}' | sed 's/,//' | sed 's/%//'" 2>/dev/null)

if [ -n "$cpu_usage" ] && [ "$cpu_usage" != "" ]; then
    # Format as fixed width: " 12.3%"
    printf "%5.1f%%" "$cpu_usage"
else
    echo " N/A%"
fi