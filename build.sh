#!/bin/bash

set -e

echo "OPERA Docker Build Script"
echo "=========================="
echo ""

show_usage() {
    echo "Usage: $0 [cl|ui|both]"
    echo ""
    echo "Options:"
    echo "  cl    - Build command-line version only (opera:cl)"
    echo "  ui    - Build UI version only (opera:ui)"
    echo "  both  - Build both versions (default)"
    echo ""
    echo "Examples:"
    echo "  $0 cl      # Build CL version"
    echo "  $0 ui      # Build UI version"
    echo "  $0 both    # Build both versions"
    echo "  $0         # Build both versions (default)"
    exit 1
}

build_cl() {
    echo "Building OPERA Command-Line (CL) version..."
    echo "-------------------------------------------"
    docker build --platform linux/amd64 \
        --build-arg VERSION=cl \
        -t opera:cl \
        .
    echo ""
    echo "✓ CL version built successfully: opera:cl"
}

build_ui() {
    echo "Building OPERA UI version..."
    echo "----------------------------"
    docker build --platform linux/amd64 \
        --build-arg VERSION=ui \
        -t opera:ui \
        .
    echo ""
    echo "✓ UI version built successfully: opera:ui"
}

VERSION="${1:-both}"

case "$VERSION" in
    cl)
        build_cl
        ;;
    ui)
        build_ui
        ;;
    both)
        build_cl
        echo ""
        build_ui
        ;;
    -h|--help)
        show_usage
        ;;
    *)
        echo "Error: Invalid option '$VERSION'"
        echo ""
        show_usage
        ;;
esac

echo ""
echo "=========================="
echo "Build complete!"
echo ""
echo "Available images:"
docker images | grep opera || echo "No OPERA images found"
echo ""
echo "Available images:"
docker images | grep opera || echo "No OPERA images found"
