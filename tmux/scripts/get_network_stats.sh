#!/bin/bash

if [ -z "$TMUX" ]; then
    exit 0
fi

CACHE="/tmp/tmux_net_cache_$(id -u)"

# Get cumulative bytes for en0 (Link layer line has the totals)
stats=$(timeout 2 netstat -ib 2>/dev/null | awk '/^en0.*<Link#/{print $7, $10; exit}')

if [ -z "$stats" ]; then
    echo "↓-- ↑--"
    exit 0
fi

rx_bytes=$(echo "$stats" | awk '{print $1}')
tx_bytes=$(echo "$stats" | awk '{print $2}')
now=$(date +%s)

prev_rx=0; prev_tx=0; prev_time=$now

if [ -f "$CACHE" ]; then
    read -r prev_rx prev_tx prev_time < "$CACHE"
fi

echo "$rx_bytes $tx_bytes $now" > "$CACHE"

elapsed=$(( now - prev_time ))
[ "$elapsed" -le 0 ] && elapsed=1

rx_rate=$(( (rx_bytes - prev_rx) / elapsed ))
tx_rate=$(( (tx_bytes - prev_tx) / elapsed ))

# Clamp negative values (can happen on first run or counter reset)
[ "$rx_rate" -lt 0 ] && rx_rate=0
[ "$tx_rate" -lt 0 ] && tx_rate=0

format_rate() {
    local rate=$1
    if [ "$rate" -ge 1048576 ]; then
        printf "%-3dMB/s" $(( rate / 1048576 ))
    else
        printf "%-3dKB/s" $(( rate / 1024 ))
    fi
}

echo "↓$(format_rate $rx_rate) ↑$(format_rate $tx_rate)"
