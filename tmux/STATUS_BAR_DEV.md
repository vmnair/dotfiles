# Tmux Status Bar Color-Coded Monitoring Implementation

## Date: 2025-09-11

## Summary
Implemented color-coded status bar monitoring for CPU, memory, and battery with Activity Monitor-accurate memory reporting and user-defined thresholds.

## Problem Statement
User requested:
1. CPU color coding: ≥30% yellow, ≥80% red
2. Memory color coding: ≤60% available yellow, ≤30% available red
3. Battery color coding: <50% yellow, <20% red
4. Memory reporting issue: Always showing ~60% when Activity Monitor showed 70%+
5. Memory display preference: "used/total GB" format instead of percentage

## Solution Implemented

### 1. Enhanced CPU Usage Script
**File**: `/Users/vinodnair/dotfiles/tmux/get_cpu_usage.sh`

**Key Features**:
- Added color coding based on CPU usage thresholds
- Maintains original percentage format
- Uses tmux color formatting: `#[fg=color]text#[fg=white]`

**Color Logic**:
```bash
if [ "$cpu_int" -ge 80 ]; then
    echo "#[fg=red]${formatted_cpu}#[fg=white]"
elif [ "$cpu_int" -ge 30 ]; then
    echo "#[fg=yellow]${formatted_cpu}#[fg=white]"
else
    echo "${formatted_cpu}"
fi
```

### 2. New Memory Usage Script  
**File**: `/Users/vinodnair/dotfiles/tmux/get_memory_usage.sh` (created)

**Key Features**:
- Uses Activity Monitor methodology: Anonymous + Wired pages
- Fixed page size detection (16384 bytes on Apple Silicon vs 4096 on Intel)
- Displays "used/total GB" format as requested
- Color coding based on available memory percentage

**Memory Calculation Fix**:
- **Previous**: Used Active + Wired + Compressed pages
- **Current**: Uses Anonymous + Wired pages (matches Activity Monitor's "App Memory" + "Wired Memory")
- **Result**: 18/96GB vs Activity Monitor's ~19GB (much more accurate)

**Activity Monitor Correlation**:
```bash
# vm_stat -> Activity Monitor mapping
Anonymous pages -> App Memory
Wired pages -> Wired Memory
Memory Used = Anonymous + Wired
```

### 3. Enhanced Battery Status Script
**File**: `/Users/vinodnair/dotfiles/tmux/get_battery_status.sh`

**Key Features**:
- Added color coding for battery percentage
- Maintains existing icon system (■ = plugged, ▲ = charging, ▼ = battery)
- Color coding applies to both icon and percentage

**Icon Logic**:
- **■**: AC Power, not charging (full/maintenance mode)
- **▲**: AC Power, actively charging
- **▼**: On battery power (discharging)

### 4. Updated Tmux Configuration
**File**: `/Users/vinodnair/dotfiles/tmux/.tmux.conf`

**Changes**:
- Line 95: Replaced inline memory calculation with new script
- **Before**: Complex inline `vm_stat` command showing GB only
- **After**: `#(~/dotfiles/tmux/get_memory_usage.sh)` with color coding

```bash
# Before
set -g status-right "... ▤ #(timeout 2 sh -c \"vm_stat | grep -E '(free|inactive)' | awk 'BEGIN{total=0} {total+=\\\$3} END{print int(total*16384/1024/1024/1024) \\\"GB\\\"}' \" 2>/dev/null || echo 'N/A') ..."

# After  
set -g status-right "... ▤ #(~/dotfiles/tmux/get_memory_usage.sh) ..."
```

## Technical Details

### Color Coding Thresholds

**CPU Usage**:
- Normal: <30% (white)
- Warning: ≥30% (yellow)
- Critical: ≥80% (red)

**Memory Usage** (based on available memory):
- Normal: >60% available (white)
- Warning: ≤60% available (yellow)  
- Critical: ≤30% available (red)

**Battery Level**:
- Normal: ≥50% (white)
- Warning: <50% (yellow)
- Critical: <20% (red)

### Memory Reporting Accuracy

**Issue Root Cause**:
1. Incorrect page size assumption (4KB vs actual 16KB)
2. Wrong memory categories (Active vs Anonymous pages)
3. Inline calculation vs dedicated script

**Resolution**:
1. Dynamic page size detection from vm_stat output
2. Activity Monitor methodology: Anonymous + Wired pages only
3. Dedicated script with proper error handling

**Before vs After**:
- **Before**: Always ~60% (incorrect calculation)
- **After**: 18/96GB (~19% used, matches Activity Monitor's 19.41GB)

### Cross-Platform Compatibility

**Page Size Detection**:
```bash
page_size=$(echo "$memory_info" | grep "page size" | awk '{print $8}' | tr -d '()')
if [ -z "$page_size" ]; then
    page_size=16384  # Default for Apple Silicon
fi
```

**Fallback Mechanisms**:
- Timeout commands for reliability
- Default values when detection fails
- "N/A" output for error states

## Performance Optimizations

### 1. Removed Redundant Code
- Eliminated bc dependency and complex decimal calculations
- Simplified memory calculation to integer math
- Removed unused test functions and files

### 2. Efficient Parsing
- Single vm_stat call with targeted grep/awk parsing
- Cached system_profiler call for total memory
- Minimal external command dependencies

### 3. Error Handling
- 2-second timeouts on all external commands
- Graceful fallbacks for missing data
- Consistent "N/A" output format

## Files Modified

### Created
1. `/Users/vinodnair/dotfiles/tmux/get_memory_usage.sh` - New memory monitoring script

### Modified  
1. `/Users/vinodnair/dotfiles/tmux/get_cpu_usage.sh` - Added color coding
2. `/Users/vinodnair/dotfiles/tmux/get_battery_status.sh` - Added color coding
3. `/Users/vinodnair/dotfiles/tmux/.tmux.conf` - Updated status bar configuration (line 95)

### Cleaned Up
- Removed all temporary test files (`test_*.sh`)
- Optimized memory script (removed bc dependency)

## Current Status Bar Output

**Format**: `▣ CPU% ▤ USED/TOTALGB ICON BATTERY% DATE TIME`

**Example**: `▣ 10.8% ▤ 18/96GB ■ 89% Sep 11 4:30 PM`

**Color Behavior**:
- All values show in white under normal conditions
- Individual metrics change to yellow/red when thresholds are exceeded
- Colors reset to white after the colored value

## Testing and Validation

### Memory Accuracy Test
- **Activity Monitor**: 19.41 GB used
- **Our Script**: 18 GB used  
- **Difference**: 1.41 GB (7.3% variance, acceptable for real-time monitoring)

### Color Coding Validation
- Scripts include tmux color formatting codes
- Colors trigger automatically when thresholds are met
- Manual testing confirmed proper color display in tmux sessions

## Future Enhancements

### Potential Improvements
1. Configurable thresholds via config file
2. Additional monitoring metrics (disk usage, network)
3. Historical trending indicators
4. Alert sounds/notifications for critical thresholds

### Maintenance Notes
- Monitor for macOS updates affecting vm_stat output format
- Verify page size detection on Intel Macs
- Test across different tmux versions

## Rollback Instructions

If issues arise, restore original configuration:

1. **Tmux config line 95**:
```bash
set -g status-right "#[fg=cyan]#(~/dotfiles/tmux/get_ai_model.sh) #[fg=white]▣ #(~/dotfiles/tmux/get_cpu_usage.sh) ▤ #(timeout 2 sh -c \"vm_stat | grep -E '(free|inactive)' | awk 'BEGIN{total=0} {total+=\\\$3} END{print int(total*16384/1024/1024/1024) \\\"GB\\\"}' \" 2>/dev/null || echo 'N/A') #(~/dotfiles/tmux/get_battery_status.sh) %b %d %I:%M %p"
```

2. **Remove color coding**: Edit scripts to remove `#[fg=color]` formatting
3. **Delete new file**: Remove `get_memory_usage.sh` if needed

---

## Date: 2026-01-01

## Weather Location Accuracy Fix

### Problem
Weather was showing Houston, TX (HOU) instead of Houma, LA - IP geolocation via `ipinfo.io` was inaccurate.

### Solution
1. Switched primary geolocation to `ip-api.com` (more accurate)
2. Added state code to disambiguate cities (e.g., `HOU,LA` vs `HOU,TX`)
3. Kept `ipinfo.io` as fallback

### Changes to `get_weather.sh`

**Location Detection** (lines 110-119):
```bash
# Get city and state from IP geolocation (ip-api.com is more accurate than ipinfo.io)
ip_api_response=$(curl -s --max-time 2 "http://ip-api.com/json" 2>/dev/null)
city=$(echo "$ip_api_response" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
state=$(echo "$ip_api_response" | grep -o '"region":"[^"]*"' | cut -d'"' -f4)

# Fallback to ipinfo.io if ip-api.com fails
if [[ -z "$city" ]]; then
    city=$(curl -s --max-time 2 "ipinfo.io/city" 2>/dev/null)
    state=""
fi
```

**Display Format** (lines 150-157):
```bash
city_code=$(get_city_code "$city")
# Add state code if available (e.g., HOU,LA)
if [[ -n "$state" ]]; then
    location_code="${city_code},${state}"
else
    location_code="${city_code}"
fi
weather_minimal="${icon} ${temp} (${location_code})"
```

**Result**: Weather now shows `󰖙 45°F (HOU,LA)` with correct location.

---

## Pomodoro Timer Implementation

### Summary
Implemented a pomodoro timer with status bar display, sound notifications, and tmux keybindings.

### Files Created
- `/Users/vinodnair/dotfiles/tmux/pomodoro.sh` - Main timer script

### Files Modified
- `/Users/vinodnair/dotfiles/tmux/.tmux.conf` - Keybindings and status bar

### Configuration
```bash
WORK_DURATION=$((25 * 60))       # 25 minutes
SHORT_BREAK=$((5 * 60))          # 5 minutes
LONG_BREAK=$((15 * 60))          # 15 minutes
CYCLES_BEFORE_LONG_BREAK=4
```

### Keybindings
| Key | Action |
|-----|--------|
| `<prefix> t` | Start/Resume timer |
| `<prefix> T` | Pause timer |
| `<prefix> x` | Cancel timer |
| `<prefix> M-t` | Full reset (cancel + reset cycle count) |

### Status Bar Display
| State | Display | Color |
|-------|---------|-------|
| Idle | (nothing) | - |
| Work | `🍅 24:59` | Yellow (red in last 2 min) |
| Short break | `☕ 4:59` | Green (yellow in last 1 min) |
| Long break | `🧘 14:59` | Green (yellow in last 2 min) |
| Paused | `⏸ 12:34` | White |

### Workflow
1. `<prefix> t` → Start 25 min work session
2. Timer ends → Sound plays → Auto-starts 5 min break
3. Break ends → Sound plays → Timer disappears (idle)
4. When ready, `<prefix> t` → Next work session
5. After 4 work sessions → 15 min long break

### State Management
State files stored in `/tmp/`:
- `pomodoro_end_time` - Unix timestamp when timer ends
- `pomodoro_mode` - Current mode: `work`, `short_break`, `long_break`, `paused`, `idle`
- `pomodoro_paused_remaining` - Seconds remaining when paused
- `pomodoro_count` - Completed work cycles (0-4)

### Sound Notifications
- **macOS**: Uses `afplay` with system sounds
  - Work end: `/System/Library/Sounds/Glass.aiff`
  - Break end: `/System/Library/Sounds/Ping.aiff`
- **Linux**: Falls back to `paplay` or `aplay`

### Tmux Config Changes

**Status interval** (for smooth countdown):
```bash
set -g status-interval 1
```

**Keybindings**:
```bash
unbind t  # unbind default clock
unbind P  # cleanup old bindings
unbind O
unbind X
unbind M-p
bind t run-shell "~/dotfiles/tmux/pomodoro.sh start >/dev/null 2>&1"
bind T run-shell "~/dotfiles/tmux/pomodoro.sh pause >/dev/null 2>&1"
bind x run-shell "~/dotfiles/tmux/pomodoro.sh cancel >/dev/null 2>&1"
bind M-t run-shell "~/dotfiles/tmux/pomodoro.sh reset >/dev/null 2>&1"
```

**Status bar**:
```bash
set -g status-right "#(~/dotfiles/tmux/pomodoro.sh status)  \
  #[fg=white]#(~/dotfiles/tmux/get_weather.sh) \
  ..."
```

### Testing
To test with short durations, temporarily modify `pomodoro.sh`:
```bash
WORK_DURATION=30    # 30 seconds
SHORT_BREAK=10      # 10 seconds
LONG_BREAK=15       # 15 seconds
```

### Notes
- Timer only appears when active (idle = clean status bar)
- Sound plays at exact timer end regardless of status bar refresh rate
- Old keybindings (P, O, X, M-p) should be unbound; restart tmux server if they persist: `tmux kill-server`