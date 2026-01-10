#!/bin/bash

# OPERA Docker Wrapper Script
# Allows running OPERA with simplified arguments, handling Docker mounting automatically.

IMAGE="opera:latest"

# Function to show usage
show_help() {
    docker run --rm --platform linux/amd64 $IMAGE -h
}

# Start building the Docker command
DOCKER_CMD="docker run --rm --platform linux/amd64"
ARGS=("$@")
INPUT_FILE=""
HAS_STD=false

# 1. Parse arguments to find input file and detect flags
for ((i=0; i<$#; i++)); do
    arg="${ARGS[$i]}"

    # Check for help
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        show_help
        exit 0
    fi

    # Check for standardization flag
    if [[ "$arg" == "-st" || "$arg" == "--Standardize" ]]; then
        HAS_STD=true
    fi

    # Check for input file flags
    # Primary inputs that determine the working directory
    IS_INPUT_FLAG=false

    # Structure inputs
    if [[ "$arg" == "-s" || "$arg" == "--SDF" || "$arg" == "--MOL" || "$arg" == "--SMI" ]]; then IS_INPUT_FLAG=true; fi

    # Descriptor/Matlab inputs
    if [[ "$arg" == "-d" || "$arg" == "--Descriptors" ]]; then IS_INPUT_FLAG=true; fi
    if [[ "$arg" == "--Mat" || "$arg" == "--ascii" ]]; then IS_INPUT_FLAG=true; fi

    # Ambiguous -m flag (Model list vs Matlab input)
    # If the next argument is an existing file, treat -m as input
    if [[ "$arg" == "-m" ]]; then
        NEXT_ARG="${ARGS[$i+1]}"
        if [ -n "$NEXT_ARG" ] && [ -f "$NEXT_ARG" ]; then
            IS_INPUT_FLAG=true
        fi
    fi

    # Auxiliary inputs (Salts, Labels, MolIDs) - these should be in the same dir as primary usually
    if [[ "$arg" == "-i" || "$arg" == "--MolID" ]]; then IS_INPUT_FLAG=true; fi
    if [[ "$arg" == "-t" || "$arg" == "--SaltInfo" ]]; then IS_INPUT_FLAG=true; fi
    if [[ "$arg" == "-l" || "$arg" == "--Labels" ]]; then IS_INPUT_FLAG=true; fi

    if [ "$IS_INPUT_FLAG" = true ]; then
        # Use the first valid input found to set the mount point
        if [ -z "$INPUT_FILE" ]; then
             INPUT_FILE="${ARGS[$i+1]}"
        fi
    fi
done

# If no input flag, but args exist, the first arg might be the file (legacy check)
if [ -z "$INPUT_FILE" ] && [ $# -gt 0 ] && [[ ! "${ARGS[0]}" =~ ^- ]]; then
    if [ -f "${ARGS[0]}" ]; then
        INPUT_FILE="${ARGS[0]}"
    fi
fi

# If we found an input file, handle mounting
if [ -n "$INPUT_FILE" ]; then
    # Get absolute path and directory
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS realpath alternative
        ABS_FILE=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$INPUT_FILE")
    else
        ABS_FILE=$(realpath "$INPUT_FILE")
    fi
    
    INPUT_DIR=$(dirname "$ABS_FILE")
    FILE_NAME=$(basename "$ABS_FILE")
    
    # Mount the input directory to /data
    # We mount it as /data/input_dir to avoid conflict if the container uses /data/input/ internally strictly
    # But usually /data is WORKDIR. Let's use /data.
    DOCKER_CMD="$DOCKER_CMD -v \"$INPUT_DIR\":/data -w /data"
    
    # Workaround for KNIME internal path issue (-st flag)
    # The container expects /root/Sample_input/input.sdf for proper standardization workflow
    if [ "$HAS_STD" = true ]; then
        # Create a temp dir for the workaround mapping
        TMP_DIR="$(pwd)/.opera_tmp_$$"
        mkdir -p "$TMP_DIR"
        cp "$ABS_FILE" "$TMP_DIR/input.sdf"
        
        # Mount the temp dir to the hardcoded KNIME path
        DOCKER_CMD="$DOCKER_CMD -v \"$TMP_DIR\":/root/Sample_input"
        
        # Cleanup trap
        trap "rm -rf \"$TMP_DIR\"" EXIT
    fi
    
    # Reconstruct arguments replacing the host path with the container path
    # We'll just run the image and let it parse the args, but we need to pass the *container* path for the input file.
    
    FINAL_ARGS=()
    SKIP_NEXT=false
    
    for arg in "$@"; do
        if [ "$SKIP_NEXT" = true ]; then
            SKIP_NEXT=false
            continue
        fi
        
        # Check if this arg matches our identified input file
        # We check both the exact string and full path match
        CANONICAL_ARG=""
        if [ -f "$arg" ]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                 CANONICAL_ARG=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$arg")
            else
                 CANONICAL_ARG=$(realpath "$arg")
            fi
        fi

        # Rewrite arguments:
        # 1. The main detected input file -> /data/filename
        # 2. ANY other file argument that resides in the SAME directory -> /data/filename
        # 3. Flags passed through as-is

        if [[ -n "$CANONICAL_ARG" && "$CANONICAL_ARG" == "$ABS_FILE" ]]; then
             # This is the primary input file
             FINAL_ARGS+=("/data/$FILE_NAME")
        elif [[ -n "$CANONICAL_ARG" && "$(dirname "$CANONICAL_ARG")" == "$INPUT_DIR" ]]; then
             # This is another file in the same directory (e.g. salts, labels)
             # We can validly rewrite it to the container path
             OTHER_NAME=$(basename "$CANONICAL_ARG")
             FINAL_ARGS+=("/data/$OTHER_NAME")
        else
             # Flag or file outside mount point (pass as is, might fail if path expected)
             FINAL_ARGS+=("$arg")
        fi
    done
    
    echo "Running OPERA on $FILE_NAME..."
    eval $DOCKER_CMD $IMAGE "${FINAL_ARGS[@]}"
else
    # No input file found, just run with passed args (maybe help or version)
    eval $DOCKER_CMD $IMAGE "$@"
fi
