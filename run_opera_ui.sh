#!/bin/bash

# OPERA UI Runner (Unified Script)
# Works on macOS and Linux

OS="$(uname -s)"
IMAGE="opera:ui"

echo "Starting OPERA UI..."
echo "Platform: $OS"
echo ""

# Ensure output directory exists (mapped for results)
mkdir -p output

if [[ "$OS" == "Darwin" ]]; then
    # --- macOS Configuration ---
    
    # 1. Check for XQuartz
    if ! command -v xquartz &> /dev/null && ! [ -d "/Applications/Utilities/XQuartz.app" ]; then
        echo "ERROR: XQuartz not found!"
        echo "Please install it: brew install --cask xquartz"
        exit 1
    fi
    
    # 2. Start XQuartz if not running
    if ! pgrep -x "Xquartz" > /dev/null; then
        echo "Starting XQuartz..."
        open -a XQuartz
        sleep 3
    fi

    # 3. Enable network connections (standard X11 security check)
    echo "Configuring X11 permissions..."

    # Locate xhost
    XHOST_CMD="xhost"
    if ! command -v xhost &> /dev/null; then
        if [ -f "/opt/X11/bin/xhost" ]; then
            XHOST_CMD="/opt/X11/bin/xhost"
        else
            echo "WARNING: 'xhost' command not found. X11 forwarding might fail."
        fi
    fi

    # Set DISPLAY if not set (needed for xhost to find the server)
    if [ -z "$DISPLAY" ]; then
        export DISPLAY=:0
    fi

    # Allow connections - relax permissions to ensure Docker can connect
    if ! $XHOST_CMD + > /dev/null 2>&1; then
        echo ""
        echo "ERROR: Failed to update X11 permissions."
        echo "Please ensure you have configured XQuartz:"
        echo "  1. Open XQuartz > Settings > Security"
        echo "  2. CHECK 'Allow connections from network clients'"
        echo "  3. Restart XQuartz really (Quit and Open again)"
        echo ""
    fi

    echo "Launching Container..."
    echo "NOTE: Startup may take 1-2 minutes (or 10-20 mins on Apple Silicon M1/M2)."
    echo "      Please wait for the OPERA window to appear..."
    echo "TIP:  In the file picker, look for '/Users/$USER' to access your Mac files."
    # Note: On macOS, we map /Users to /Users so paths match natively
    docker run --rm --platform linux/amd64 \
        -e DISPLAY=host.docker.internal:0 \
        -e LIBGL_ALWAYS_INDIRECT=1 \
        -v "$(pwd):/data/host" \
        -v /Users:/Users \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -w /data/host \
        $IMAGE

    # Cleanup permissions
    $XHOST_CMD - > /dev/null 2>&1

elif [[ "$OS" == "Linux" ]]; then
    # --- Linux Configuration ---

    # 1. Permission check
    echo "Configuring X11 permissions..."
    xhost +local:docker > /dev/null 2>&1

    # Detect the actual user (in case running as root via sudo)
    ACTUAL_USER="${SUDO_USER:-$USER}"
    ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

    echo "Launching Container..."
    # On Linux, we map the user's home directory to allow easy file navigation
    docker run --rm --platform linux/amd64 \
        --network=host \
        -e DISPLAY=$DISPLAY \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        -v "$HOME:/home/user" \
        -v "$ACTUAL_HOME:$ACTUAL_HOME" \
        -v "$(pwd):/data/host" \
        -w /data/host \
        $IMAGE
        
    # Cleanup
    xhost -local:docker > /dev/null 2>&1

else
    echo "Unsupported platform for this script: $OS"
    echo "If you are on Windows, please use 'run_opera_ui.ps1'"
    exit 1
fi

echo ""
echo "OPERA UI Session Finished."
