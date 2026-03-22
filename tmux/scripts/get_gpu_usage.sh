#!/bin/bash

if [ -z "$TMUX" ]; then
    exit 0
fi

gpu_info=$(timeout 2 ioreg -r -d 1 -w 0 -c AGXAccelerator 2>/dev/null)

if [ -z "$gpu_info" ]; then
    echo "N/A"
    exit 0
fi

# Extract "Device Utilization %" from PerformanceStatistics on Apple Silicon
# The value appears inline: ..."Device Utilization %"=<number>,...
gpu_pct=$(echo "$gpu_info" | grep -o '"Device Utilization %"=[0-9]*' | awk -F'=' '{print $2}' | head -1)

if [ -z "$gpu_pct" ] || ! [[ "$gpu_pct" =~ ^[0-9]+$ ]] || [ "$gpu_pct" -eq 0 ]; then
    exit 0
fi

if [ "$gpu_pct" -ge 80 ]; then
    echo " 󰍛 #[fg=red]${gpu_pct}%#[fg=white]"
elif [ "$gpu_pct" -ge 30 ]; then
    echo " 󰍛 #[fg=yellow]${gpu_pct}%#[fg=white]"
else
    echo " 󰍛 ${gpu_pct}%"
fi
