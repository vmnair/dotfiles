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

# Convert day icons to night equivalents
convert_to_night_icon() {
    local icon="$1"
    case "$icon" in
        "☀️"|"🌤"|"⛅️"|"🌥") echo "🌙" ;;  # Clear/partly cloudy -> moon
        *) echo "$icon" ;;  # Keep other icons (rain, snow, etc.)
    esac
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
    
    # Convert to night icon if needed
    if is_night; then
        icon=$(convert_to_night_icon "$icon")
    fi
    
    weather_minimal="${icon} ${temp}"

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
