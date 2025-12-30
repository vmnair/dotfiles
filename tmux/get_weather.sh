#!/usr/bin/env bash

# Weather script for tmux status bar
# Uses ipinfo.io for location and wttr.in for weather
# Caches result to avoid excessive API calls
#
# Toggle verbose mode (shows city + condition):
#   touch ~/dotfiles/tmux/.weather_verbose    # Enable
#   rm ~/dotfiles/tmux/.weather_verbose       # Disable
#
# Force refresh (also triggered by tmux <prefix> r):
#   touch ~/dotfiles/tmux/.weather_refresh

CACHE_FILE="/tmp/tmux_weather_cache"
CACHE_FILE_VERBOSE="/tmp/tmux_weather_cache_verbose"
CACHE_MAX_AGE=600  # 10 minutes in seconds
VERBOSE_FLAG="$HOME/dotfiles/tmux/.weather_verbose"
REFRESH_FLAG="$HOME/dotfiles/tmux/.weather_refresh"

# Check if it's night time (between 6 PM and 6 AM)
is_night() {
    local hour=$(date +%H)
    [[ $hour -ge 18 || $hour -lt 6 ]]
}

# Convert emoji to Nerd Font icon (respects tmux colors)
convert_to_nerd_icon() {
    local icon="$1"
    local is_night="$2"

    case "$icon" in
        "☀️"|"🌞")
            if [ "$is_night" = "true" ]; then
                echo "󰖔"  # moon
            else
                echo "󰖙"  # sun
            fi
            ;;
        "🌤"|"⛅️"|"⛅")
            if [ "$is_night" = "true" ]; then
                echo "󰼳"  # partly cloudy night
            else
                echo "󰖕"  # partly cloudy day
            fi
            ;;
        "🌥"|"☁️"|"☁")
            echo "󰖐"  # cloudy
            ;;
        "🌧"|"🌦"|"💧")
            echo "󰖗"  # rain
            ;;
        "⛈"|"🌩"|"⚡")
            echo "󰙾"  # thunderstorm
            ;;
        "🌨"|"❄️"|"❄")
            echo "󰖘"  # snow
            ;;
        "🌫"|"🌁")
            echo "󰖑"  # fog
            ;;
        "🌙"|"🌛"|"🌜")
            echo "󰖔"  # moon
            ;;
        *)
            echo "󰖐"  # default: cloud
            ;;
    esac
}

# Generate dynamic city abbreviation (bash 3.2 compatible)
get_city_code() {
    local city="$1"
    # Remove trailing whitespace/newlines
    city=$(echo "$city" | tr -d '\n' | sed 's/[[:space:]]*$//')

    local word_count=$(echo "$city" | wc -w | tr -d ' ')

    if [[ $word_count -gt 1 ]]; then
        # Multi-word: take first letter of each word (e.g., "New York" -> "NY")
        echo "$city" | awk '{for(i=1;i<=NF;i++) printf toupper(substr($i,1,1))}'
    else
        # Single word: take first 3 letters (e.g., "Boston" -> "BOS")
        echo "$city" | cut -c1-3 | tr '[:lower:]' '[:upper:]'
    fi
}

# Determine display mode
verbose=false
[[ -f "$VERBOSE_FLAG" ]] && verbose=true

# Check for manual refresh trigger (created by tmux reload)
if [[ -f "$REFRESH_FLAG" ]]; then
    rm -f "$CACHE_FILE" "$CACHE_FILE_VERBOSE" "$REFRESH_FLAG"
fi

# Check if cache exists and is fresh
if [[ -f "$CACHE_FILE" ]]; then
    cache_age=$(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null)))
    if [[ $cache_age -lt $CACHE_MAX_AGE ]]; then
        # Return appropriate format from cache
        if $verbose && [[ -f "$CACHE_FILE_VERBOSE" ]]; then
            cat "$CACHE_FILE_VERBOSE"
        else
            cat "$CACHE_FILE"
        fi
        exit 0
    fi
fi

# Get city from IP geolocation
city=$(curl -s --max-time 2 "ipinfo.io/city" 2>/dev/null)

# Fetch weather for detected city
# Use 'u' flag for US units (Fahrenheit)
if [[ -n "$city" ]]; then
    # URL encode city name (replace spaces with +)
    city_encoded=$(echo "$city" | sed 's/ /+/g')
    # %c = icon, %t = temperature, %C = condition text
    weather_full=$(curl -s --max-time 3 "wttr.in/${city_encoded}?format=%c+%t+%C&u" 2>/dev/null | head -1)
else
    weather_full=$(curl -s --max-time 3 "wttr.in/?format=%c+%t+%C&u" 2>/dev/null | head -1)
    city="Unknown"
fi

# Validate response (should contain temperature)
if [[ -n "$weather_full" && "$weather_full" != *"Unknown"* && "$weather_full" =~ [0-9] ]]; then
    # Clean up extra spaces
    weather_full=$(echo "$weather_full" | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

    # Extract icon and temperature only (minimal format)
    # Format is: "icon temp condition" -> extract first two parts
    icon=$(echo "$weather_full" | awk '{print $1}')
    temp=$(echo "$weather_full" | awk '{print $2}')
    
    # Convert emoji to Nerd Font icon
    if is_night; then
        icon=$(convert_to_nerd_icon "$icon" "true")
    else
        icon=$(convert_to_nerd_icon "$icon" "false")
    fi
    
    city_code=$(get_city_code "$city")
    weather_minimal="${icon} ${temp} (${city_code})"

    # Verbose format: City: icon temp condition
    weather_verbose="${city}: ${weather_full}"

    # Cache both formats
    echo "$weather_minimal" > "$CACHE_FILE"
    echo "$weather_verbose" > "$CACHE_FILE_VERBOSE"

    # Output based on mode
    if $verbose; then
        echo "$weather_verbose"
    else
        echo "$weather_minimal"
    fi
else
    # Return cached value if available
    if $verbose && [[ -f "$CACHE_FILE_VERBOSE" ]]; then
        cat "$CACHE_FILE_VERBOSE"
    elif [[ -f "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
    else
        echo ""
    fi
fi
