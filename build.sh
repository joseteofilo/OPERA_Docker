#!/bin/bash

set -e

echo "OPERA Docker Build Script"
echo "=========================="
echo ""

# Check which version to build
if [ "$1" == "ui" ]; then
    echo "Building OPERA UI version..."

    if [ ! -f "OPERA2.9_UI_mcr.tar.xz" ]; then
        echo "ERROR: OPERA2.9_UI_mcr.tar.xz not found!"
        echo ""
        echo "Please download from:"
        echo "https://github.com/USEPA/OPERA/releases"
        echo ""
        echo "Place OPERA2.9_UI_mcr.tar.xz in this directory and run again."
        exit 1
    fi

    docker build -f Dockerfile.ui -t opera:2.9-ui -t opera:ui .
    echo ""
    echo "Build complete! To run UI:"
    echo "  ./run_opera_ui.sh"

elif [ "$1" == "cl" ] || [ -z "$1" ]; then
    echo "Building OPERA Command-Line version..."

    if [ ! -f "OPERA2.9_CL_mcr.tar.xz" ]; then
        echo "ERROR: OPERA2.9_CL_mcr.tar.xz not found!"
        echo ""
        echo "Please download from:"
        echo "https://github.com/USEPA/OPERA/releases"
        echo ""
        echo "Place OPERA2.9_CL_mcr.tar.xz in this directory and run again."
        exit 1
    fi

    docker build -f Dockerfile -t opera:2.9-cl -t opera:latest .
    echo ""
    echo "Build complete! To run:"
    echo "  ./run_opera.sh molecules.sdf -a"

else
    echo "Usage: ./build.sh [cl|ui]"
    echo ""
    echo "  cl  - Build command-line version (default)"
    echo "  ui  - Build UI version with X11 support"
    exit 1
fi