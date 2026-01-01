#!/bin/bash

# Pomodoro Timer for tmux status bar
# Usage: pomodoro.sh [start|pause|cancel|reset|status]
#
# Keybindings (add to .tmux.conf):
#   bind P run-shell "~/dotfiles/tmux/pomodoro.sh start"
#   bind O run-shell "~/dotfiles/tmux/pomodoro.sh pause"
#   bind X run-shell "~/dotfiles/tmux/pomodoro.sh cancel"
#   bind M-p run-shell "~/dotfiles/tmux/pomodoro.sh reset"

# Configuration (in seconds)
WORK_DURATION=$((25 * 60))       # 25 minutes
SHORT_BREAK=$((5 * 60))          # 5 minutes
LONG_BREAK=$((15 * 60))          # 15 minutes
CYCLES_BEFORE_LONG_BREAK=4

# State files
STATE_DIR="/tmp"
END_TIME_FILE="$STATE_DIR/pomodoro_end_time"
MODE_FILE="$STATE_DIR/pomodoro_mode"
PAUSED_REMAINING_FILE="$STATE_DIR/pomodoro_paused_remaining"
COUNT_FILE="$STATE_DIR/pomodoro_count"

# Icons
ICON_WORK="🍅"
ICON_SHORT_BREAK="☕"
ICON_LONG_BREAK="🧘"
ICON_PAUSED="⏸"
ICON_IDLE="🍅"

# Get current mode (idle if no file)
get_mode() {
    if [[ -f "$MODE_FILE" ]]; then
        cat "$MODE_FILE"
    else
        echo "idle"
    fi
}

# Get completed pomodoro count
get_count() {
    if [[ -f "$COUNT_FILE" ]]; then
        cat "$COUNT_FILE"
    else
        echo "0"
    fi
}

# Play notification sound
play_sound() {
    local sound_type="$1"  # "work_end" or "break_end"

    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        if [[ "$sound_type" == "work_end" ]]; then
            afplay /System/Library/Sounds/Glass.aiff &
        else
            afplay /System/Library/Sounds/Ping.aiff &
        fi
    else
        # Linux - try paplay first, then aplay
        if command -v paplay &>/dev/null; then
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
        elif command -v aplay &>/dev/null; then
            aplay /usr/share/sounds/sound-icons/trumpet-12.wav 2>/dev/null &
        fi
    fi
}

# Start a timer with given duration and mode
start_timer() {
    local duration="$1"
    local mode="$2"
    local end_time=$(($(date +%s) + duration))

    echo "$end_time" > "$END_TIME_FILE"
    echo "$mode" > "$MODE_FILE"
    rm -f "$PAUSED_REMAINING_FILE"
}

# Format seconds as MM:SS
format_time() {
    local seconds="$1"
    printf "%02d:%02d" $((seconds / 60)) $((seconds % 60))
}

# Command: start
cmd_start() {
    local mode=$(get_mode)

    if [[ "$mode" == "paused" && -f "$PAUSED_REMAINING_FILE" ]]; then
        # Resume from pause
        local remaining=$(cat "$PAUSED_REMAINING_FILE")
        local previous_mode=$(cat "$PAUSED_REMAINING_FILE.mode" 2>/dev/null || echo "work")
        start_timer "$remaining" "$previous_mode"
    elif [[ "$mode" == "idle" ]]; then
        # Start new work session
        start_timer "$WORK_DURATION" "work"
    fi
    # If already running, do nothing
}

# Command: pause
cmd_pause() {
    local mode=$(get_mode)

    if [[ "$mode" != "idle" && "$mode" != "paused" && -f "$END_TIME_FILE" ]]; then
        local end_time=$(cat "$END_TIME_FILE")
        local now=$(date +%s)
        local remaining=$((end_time - now))

        if [[ $remaining -gt 0 ]]; then
            echo "$remaining" > "$PAUSED_REMAINING_FILE"
            echo "$mode" > "$PAUSED_REMAINING_FILE.mode"
            echo "paused" > "$MODE_FILE"
            rm -f "$END_TIME_FILE"
        fi
    fi
}

# Command: cancel
cmd_cancel() {
    echo "idle" > "$MODE_FILE"
    rm -f "$END_TIME_FILE" "$PAUSED_REMAINING_FILE" "$PAUSED_REMAINING_FILE.mode"
}

# Command: reset
cmd_reset() {
    cmd_cancel
    echo "0" > "$COUNT_FILE"
}

# Command: status (for tmux status bar)
cmd_status() {
    local mode=$(get_mode)
    local count=$(get_count)

    case "$mode" in
        idle)
            # Show nothing when idle (clean status bar)
            echo ""
            ;;
        paused)
            if [[ -f "$PAUSED_REMAINING_FILE" ]]; then
                local remaining=$(cat "$PAUSED_REMAINING_FILE")
                echo "#[fg=white]$ICON_PAUSED $(format_time $remaining)#[fg=white]"
            else
                echo "$ICON_PAUSED"
            fi
            ;;
        work|short_break|long_break)
            if [[ -f "$END_TIME_FILE" ]]; then
                local end_time=$(cat "$END_TIME_FILE")
                local now=$(date +%s)
                local remaining=$((end_time - now))

                if [[ $remaining -le 0 ]]; then
                    # Timer ended - handle transition
                    handle_timer_end "$mode"
                else
                    # Show remaining time with appropriate color
                    local icon color
                    case "$mode" in
                        work)
                            icon="$ICON_WORK"
                            if [[ $remaining -le 120 ]]; then
                                color="red"
                            else
                                color="yellow"
                            fi
                            ;;
                        short_break)
                            icon="$ICON_SHORT_BREAK"
                            if [[ $remaining -le 60 ]]; then
                                color="yellow"
                            else
                                color="green"
                            fi
                            ;;
                        long_break)
                            icon="$ICON_LONG_BREAK"
                            if [[ $remaining -le 120 ]]; then
                                color="yellow"
                            else
                                color="green"
                            fi
                            ;;
                    esac
                    echo "#[fg=$color]$icon $(format_time $remaining)#[fg=white]"
                fi
            else
                echo ""
            fi
            ;;
    esac
}

# Handle timer end and auto-transition
handle_timer_end() {
    local mode="$1"
    local count=$(get_count)

    case "$mode" in
        work)
            # Work session ended
            play_sound "work_end"
            count=$((count + 1))
            echo "$count" > "$COUNT_FILE"

            if [[ $count -ge $CYCLES_BEFORE_LONG_BREAK ]]; then
                # Start long break and reset count
                start_timer "$LONG_BREAK" "long_break"
                echo "0" > "$COUNT_FILE"
                echo "#[fg=green]$ICON_LONG_BREAK $(format_time $LONG_BREAK)#[fg=white]"
            else
                # Start short break
                start_timer "$SHORT_BREAK" "short_break"
                echo "#[fg=green]$ICON_SHORT_BREAK $(format_time $SHORT_BREAK)#[fg=white]"
            fi
            ;;
        short_break|long_break)
            # Break ended
            play_sound "break_end"
            echo "idle" > "$MODE_FILE"
            rm -f "$END_TIME_FILE"
            echo ""
            ;;
    esac
}

# Main
case "${1:-status}" in
    start)  cmd_start ;;
    pause)  cmd_pause ;;
    cancel) cmd_cancel ;;
    reset)  cmd_reset ;;
    status) cmd_status ;;
    *)
        echo "Usage: $0 [start|pause|cancel|reset|status]"
        exit 1
        ;;
esac
