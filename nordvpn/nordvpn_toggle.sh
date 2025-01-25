#!/bin/bash
# Vinod Nair MD
# This script connects and disconnects from nord VPN

#!/bin/bash

# Function to check NordVPN status
#!/bin/bash

# Check if NordVPN command exists
if ! command -v nordvpn &> /dev/null; then
    echo "NordVPN CLI not found. Please install it first."
    exit 1
fi

# Function to check NordVPN status
check_status() {
    # This command gets the full status and then checks if it contains 'Connected' or 'Disconnected'
    local full_status
    full_status=$(nordvpn status)
    if [[ $full_status == *"Connected"* ]]; then
	    echo "Connected"
    elif [[ $full_status == *"Disconnected"* ]]; then
	    echo "Disconnected"
    else
        echo "NordVPN Connection Status Unknown"
    fi
}

# Getting the current status
status=$(check_status)

# Toggle VPN connection based on the current status
if [ "$status" = "Connected" ]; then
    echo "Disconnecting from NordVPN..."
    nordvpn disconnect > /dev/null
elif [ "$status" = "Disconnected" ]; then
    echo "Connecting to NordVPN..."
    nordvpn connect > /dev/null
else
    echo "Unable to determine NordVPN status. Current status: $status"
    exit 1
fi

# Checking and displaying the new status
# new_status=$(check_status)
# echo "Current NordVPN Status: $new_status"

