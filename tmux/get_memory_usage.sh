#!/bin/bash

# Script to get memory usage in GB format with color coding for tmux status bar
# Uses Activity Monitor methodology: Active + Wired memory as "used"
# Colors: ≤60% available = yellow, ≤30% available = red
# Shows used/total GB format matching Activity Monitor

# Check if we're in a tmux session
if [ -z "$TMUX" ]; then
    exit 0
fi

# Get memory information with timeout and error handling
memory_info=$(timeout 2 vm_stat 2>/dev/null)

if [ -z "$memory_info" ]; then
    echo "N/A"
    exit 0
fi

# Get page size from vm_stat (usually 16384 on Apple Silicon, 4096 on Intel)
page_size=$(echo "$memory_info" | grep "page size" | awk '{print $8}' | tr -d '()')

if [ -z "$page_size" ]; then
    page_size=16384  # Default for Apple Silicon
fi

# Parse vm_stat output - Activity Monitor uses Anonymous + Wired as "Memory Used"
# App Memory ≈ Anonymous pages, Wired Memory = Wired pages
anonymous_pages=$(echo "$memory_info" | grep "Anonymous pages" | awk '{print $3}' | sed 's/\.//')
wired_pages=$(echo "$memory_info" | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')

# Get total physical memory from system profiler (more reliable than vm_stat totals)
total_memory_gb=$(system_profiler SPHardwareDataType | grep "Memory:" | awk '{print $2}')

# Calculate memory usage using Activity Monitor methodology
if [ -n "$anonymous_pages" ] && [ -n "$wired_pages" ] && [ -n "$total_memory_gb" ]; then
    # Calculate used memory in GB (Anonymous + Wired pages, matching Activity Monitor)
    used_memory_bytes=$(( (anonymous_pages + wired_pages) * page_size ))
    used_memory_gb=$(( used_memory_bytes / 1024 / 1024 / 1024 ))
    formatted_memory="${used_memory_gb}/${total_memory_gb}GB"
    
    # Calculate percentage for color coding
    total_memory_bytes=$(( total_memory_gb * 1024 * 1024 * 1024 ))
    used_percent=$(( used_memory_bytes * 100 / total_memory_bytes ))
    available_percent=$(( 100 - used_percent ))
    
    # Apply color coding based on available memory thresholds
    if [ "$available_percent" -le 30 ]; then
        echo "#[fg=red]${formatted_memory}#[fg=white]"
    elif [ "$available_percent" -le 60 ]; then
        echo "#[fg=yellow]${formatted_memory}#[fg=white]"
    else
        echo "${formatted_memory}"
    fi
else
    echo "N/A"
fi