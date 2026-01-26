# OPERA Docker

This guide provides comprehensive instructions for running OPERA (OPEn structure-activity/property Relationship App) in Docker containers for both Command-Line (CL) and Graphical User Interface (UI) versions.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Building OPERA Docker Images](#building-opera-docker-images)
  - [Build Images](#build-images)
    - [Build CL Version Only](#build-cl-version-only)
    - [Build UI Version Only](#build-ui-version-only)
    - [Build PAR Version Only](#build-par-version-only)
    - [Build All Versions](#build-all-versions)
  - [Verify Installation](#verify-installation)
- [Command-Line (CL) Version](#command-line-cl-version)
- [Graphical User Interface (UI) Version](#graphical-user-interface-ui-version)
- [Parallel (PAR) Version](#parallel-par-version)
  - [PAR Version Requirements](#par-version-requirements)
  - [PAR Version Usage](#par-version-usage)
- [Troubleshooting](#troubleshooting)
  - [CL Version Issues](#cl-version-issues)
  - [UI Version Issues](#ui-version-issues)
  - [General Issues](#general-issues)
- [Technical Details](#technical-details)
  - [File Structure](#file-structure)
- [Quick Reference Commands](#quick-reference-commands)
- [Support and Contributing](#support-and-contributing)

## Prerequisites

### For All Platforms

- **Docker Desktop** (macOS/Windows) or **Docker Engine** (Linux): https://www.docker.com/get-started/
- **OPERA Installer Files** — The Docker build process will automatically download the latest version from: https://github.com/kmansouri/OPERA/releases/latest
  - No manual download required - the Dockerfile fetches the latest release automatically

### For UI Version on macOS

- **XQuartz**:
  ```bash
  brew install --cask xquartz
  ```
- **IMPORTANT**: UI performance on Apple Silicon (M1/M2/M3) can be slow due to x86 emulation.

### For UI Version on Linux

- X11 server (usually pre-installed on desktop distributions)
- **Important**: If running Docker commands as root (via `sudo` or `su`), you must set the DISPLAY environment variable: `export DISPLAY=:0`

### For UI Version on Windows

- **Windows Requirements:** Install [VcXsrv](https://github.com/ArcticaProject/vcxsrv) (or similar X Server) and run it with "Disable access control" checked.

### Docker Resource Requirements

- **CL Version**: Minimum 2GB RAM, 2 CPU cores
- **UI Version**: Minimum 4GB RAM, 4 CPU cores (8GB+ recommended)
- **Apple Silicon**: Increase Docker Desktop resources to maximum available for UI version

## Building OPERA Docker Images

OPERA provides both Command-Line (CL) and Graphical User Interface (UI) versions. You can build either or both using the unified Dockerfile.

### Build Images

Navigate to OPERA directory first:
```bash
cd /path/to/OPERA_Docker
```

#### Build CL Version Only

Recommended for most users who only need command-line predictions.

```bash
# Using build script
./build.sh cl

# Or use docker directly
docker build --platform linux/amd64 --build-arg VERSION=cl -t opera:cl .

# If build fails, try with --no-cache
docker build --no-cache --platform linux/amd64 --build-arg VERSION=cl -t opera:cl .
```

**Build Time:** 5-10 minutes (15-30 minutes on Apple Silicon)

**Build Time:** 5-10 minutes (15-30 minutes on Apple Silicon)

#### Build UI Version Only

For users who need the graphical interface.

```bash
# Using build script
./build.sh ui

# Or use docker directly
docker build --platform linux/amd64 --build-arg VERSION=ui -t opera:ui .

# If build fails, try with --no-cache
docker build --no-cache --platform linux/amd64 --build-arg VERSION=ui -t opera:ui .
```

#### Build PAR Version Only

For users who need the parallel processing version.

```bash
# Using build script
./build.sh par

# Or use docker directly
docker build --platform linux/amd64 --build-arg VERSION=par -t opera:par .
```

**Build Time:** 10-15 minutes (15-30 minutes on Apple Silicon)

#### Build All Versions

Build CL, PAR, and UI versions at once.

```bash
# Using build script
./build.sh all

# Or use docker directly
docker build --platform linux/amd64 --build-arg VERSION=cl -t opera:cl . && \
docker build --platform linux/amd64 --build-arg VERSION=par -t opera:par . && \
docker build --platform linux/amd64 --build-arg VERSION=ui -t opera:ui .
```

**Build Time:** 15-25 minutes (30-60 minutes on Apple Silicon)

### Verify Installation

```bash
# Check if images were built successfully
docker images | grep opera

# Test the CL installation (show help)
docker run --rm --platform linux/amd64 opera:cl -h
```

## Command-Line (CL) Version

The recommended way to run the Command-Line version is using the provided wrapper script `run_opera.sh` (for Linux/macOS) or `run_opera.ps1` (for Windows). These scripts handle all Docker complexity (mounting volumes, mapping user IDs, handling paths) and work exactly like the native OPERA application.

#### Linux & macOS

```bash
# Make the script executable (first time only)
chmod +x run_opera.sh

# Basic Usage
./run_opera.sh -s molecules.sdf

# Full Path Usage
./run_opera.sh -s /Users/name/documents/project/test_set.sdf
```

#### Windows (PowerShell)

```powershell
# 1. First time setup: Unblock the script (Security Requirement)
Unblock-File -Path .\run_opera.ps1

# 2. Basic Usage
.\run_opera.ps1 -s molecules.sdf

# Full Path Usage
.\run_opera.ps1 -s C:\Users\name\documents\project\test_set.sdf
```

#### Common Examples

```bash
# Standardize structures and calculate all endpoints
./run_opera.sh -s input.sdf -st -a   # Linux/macOS
.\run_opera.ps1 -s input.sdf -st -a   # Windows

# Run specific endpoints (LogP and BCF)
./run_opera.sh -s input.sdf -logP -BCF
.\run_opera.ps1 -s input.sdf -logP -BCF

# Output to a specific file
./run_opera.sh -s input.sdf -o results.csv
.\run_opera.ps1 -s input.sdf -o results.csv

# Use pre-calculated descriptors
./run_opera.sh -d descriptors.csv -o predictions.csv
.\run_opera.ps1 -d descriptors.csv -o predictions.csv
```

#### Command Reference

The `run_opera.sh` script accepts all standard OPERA arguments:

| Flag | Description |
|------|-------------|
| `-s <file>` | Input structure file (SDF, MOL, SMI) |
| `-d <file>` | Input descriptors file (CSV) |
| `-st` | **Standardize structures** (Automatically handles KNIME workflow) |
| `-o <file>` | Output file name |
| `-a` | Calculate all endpoints |
| `-logP`, `-BCF`, etc. | Calculate specific endpoints |
| `-h` | Show full help menu |

#### Manual Docker Usage (Advanced)

If you prefer to run `docker` commands manually without the wrapper script, you must handle volume mounting yourself.

**Note:** The `-st` (Standardization) flag requires a specific workaround for the KNIME workflow path if running manually. The wrapper script handles this automatically.

```bash
# Basic run (requires mounting input directory to /data)
docker run --rm --platform linux/amd64 \
  -v "$(pwd):/data" \
  -w /data \
  opera:cl \
  -s input.sdf
```

#### Custom Volume Mounting

You can mount files and directories from any location on your host machine, not just `input` and `output`:

```bash
# Mount your entire project directory (recommended approach)
docker run --rm --platform linux/amd64 \
  -v "$(pwd):/data" \
  -w /data \
  opera:cl -s your_file.sdf

# Windows PowerShell example with custom path
docker run --rm --platform linux/amd64 `
  -v "C:/Path/To/Your/Project:/data" `
  -w /data `
  opera:cl -s your_file.sdf

# Mount multiple directories from different locations (Linux/macOS example)
docker run --rm --platform linux/amd64 \
  -v "/path/to/chemistry/data:/data" \
  -v "/path/to/results:/output" \
  -w /data \
  opera:cl -s your_file.sdf
```

**Volume mounting format**: `-v "host_path:container_path"`
- `host_path`: Absolute path on your computer (Windows: `C:/...`, Linux/Mac: `/home/...`)
- `container_path`: Path inside the Docker container (can be any valid path)
- `-w /data`: Sets the working directory inside the container

**Output Files Generated**:
When you run OPERA, it creates these files in the working directory:
- `OPERA2.9_Pred.csv` - All model predictions (LogP, MP, BP, VP, WS, HL, RT, KOA, pKa, LogD, OH, BCF, BioDeg, ReadyBiodeg, KM, Koc, FUB, Clint, CACO2, CERAPP, CoMPARA, CATMoS)
- `<filename>_CDKDesc.csv` - CDK descriptors
- `<filename>_PadelDesc.csv` - PaDEL descriptors
- `<filename>_PadelFP.csv` - PaDEL fingerprints
- Various log files (`*_CDKerr.log`, `*_CDKlogfile.log`, `*_PaDELlogfile.log`, etc.)

#### Interactive Mode

```bash
# Run container interactively to execute multiple commands
docker run --rm -it --platform linux/amd64 \
  -v "$(pwd)/input:/data/input" \
  -v "$(pwd)/output:/data/output" \
  --entrypoint /bin/bash \
  opera:cl
```

Inside the container, run OPERA manually:

```bash
/usr/local/OPERA/application/run_OPERA.sh /usr/local/OPERA/v912 -s /data/input/your_file.sdf
```

## Graphical User Interface (UI) Version

If you wish to use the graphical interface of OPERA, you must use the `ui` scripts. Note that this requires an X11 server (GUI display) on your host machine.

1. **Allow permissions to execute the UI script (macOS/Linux)**:
   ```bash
   chmod +x run_opera_ui.sh
   ```
   *Note: On Linux, you might need `sudo` permissions depending on your system configuration.*

2. **Run the UI Script**:

   | Platform | Script | Command |
   | :--- | :--- | :--- |
   | **macOS / Linux** | `run_opera_ui.sh` | `./run_opera_ui.sh` |
   | **Windows** | `run_opera_ui.ps1` | `.\run_opera_ui.ps1` |

   *   **macOS Requirements:** Install [XQuartz](https://www.xquartz.org/).
   *   **Windows Requirements:** Install [VcXsrv](https://github.com/ArcticaProject/vcxsrv) (or similar X Server) and run it with "Disable access control" checked.

3. **Select Input Files**:
   When clicking **Browse** in the application, navigate to the following paths to find your local files:

   *   **macOS**: `/Users/<your_username>` (Matches your native Mac path)
   *   **Windows**: `/mnt/users/<your_username>` (Maps to `C:\Users`)
   *   **Linux**: `/home/user` (Maps to your home directory `$HOME`)
   *   **Quick Access (All)**: `/data/host` (Maps to the folder where you ran the script)

The UI scripts will map your local directories so you can browse and select files from within the OPERA application.

The MacOS/Linux implementation handles the display forwarding and file mapping automatically.

## Parallel (PAR) Version

The Parallel version allows running OPERA with parallel processing capabilities using MATLAB's Parallel Computing Toolbox. Use `run_opera_par.sh` (Linux/macOS) or `run_opera_par.ps1` (Windows).

### PAR Version Requirements

**Important:** The PAR version has higher resource requirements than the CL version due to parallel worker processes.

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **Docker Desktop Memory** | 8GB | 16-24GB |
| **Shared Memory (shm-size)** | 4GB | 8GB |
| **CPU Cores** | 2 | 4+ |

**Notes:**
- Increase Docker Desktop memory allocation in **Settings > Resources > Memory** to at least 16GB for optimal performance.
- The `-P` flag controls the number of parallel workers. Reduce this value if you experience memory issues or worker crashes.

### PAR Version Usage

#### Linux & macOS

```bash
# Make the script executable (first time only)
chmod +x run_opera_par.sh

# Run PAR version with structure file
./run_opera_par.sh -P 2 -s molecules.sdf -o predictions.csv

# With standardization (recommended for raw structures)
./run_opera_par.sh -P 2 -s molecules.sdf -st -o predictions.csv
```

#### Windows (PowerShell)

```powershell
# Unblock script (first time only)
Unblock-File -Path .\run_opera_par.ps1

# Run PAR version with structure file
.\run_opera_par.ps1 -P 2 -s molecules.sdf -o predictions.csv

# With standardization (recommended for raw structures)
.\run_opera_par.ps1 -P 2 -s molecules.sdf -st -o predictions.csv
```

#### PAR Version Examples

```bash
# Run with 2 parallel workers (recommended for most systems)
./run_opera_par.sh -P 2 -s molecules.sdf -o results.csv

# Run with 4 parallel workers (requires more memory)
./run_opera_par.sh -P 4 -s molecules.sdf -o results.csv

# Run specific endpoints with parallel processing
./run_opera_par.sh -P 2 -s molecules.sdf -e logP BCF -o results.csv

# With standardization
./run_opera_par.sh -P 2 -s molecules.sdf -st -o results.csv

# Use pre-calculated descriptors (faster if already computed)
./run_opera_par.sh -P 2 -d molecules_PadelDesc.csv -o results.csv
```

#### PAR Version Command Reference

| Flag | Description |
|------|-------------|
| `-P <num>` | Number of parallel workers (default: auto, recommend 2-4) |
| `-s <file>` | Input structure file (SDF, MOL, SMI) |
| `-d <file>` | Input descriptors file (CSV) |
| `-o <file>` | Output file name |
| `-e <endpoints>` | Specific endpoints to calculate (e.g., `logP BCF`) |
| `-st` | Standardize structures before prediction |
| `-h` | Show full help menu |

#### Troubleshooting PAR Version

- **"Killed" or worker aborts**: Reduce the number of workers with `-P 2` or `-P 1`, and increase Docker memory allocation.
- **X11/AWT errors**: The wrapper script handles this automatically with Xvfb virtual display.


## Troubleshooting

### UI Version Issues

#### Problem: UI window doesn't appear on macOS

- **Cause**: X11 forwarding not configured or XQuartz not running
- **Solution**:

```bash
# 1. Verify XQuartz is running
ps aux | grep XQuartz

# 2. If not running, start it
open -a XQuartz
sleep 2

# 3. Set DISPLAY and allow connections
export DISPLAY=:0
/opt/X11/bin/xhost +

# 4. Verify xhost command works
/opt/X11/bin/xhost
# Should show: "access control disabled, clients can connect from any host"

# 5. Try running the container again
docker run --rm --platform linux/amd64 \
  -e DISPLAY=host.docker.internal:0 \
  -e LIBGL_ALWAYS_INDIRECT=1 \
  -v "$(pwd)/input:/data/input" \
  -v "$(pwd)/output:/data/output" \
  opera:ui
```

#### Problem: `xhost: unable to open display ""`

- **Cause**: `DISPLAY` environment variable not set
- **Solution**:

```bash
export DISPLAY=:0
/opt/X11/bin/xhost +
```

#### Problem: Multiple UI containers running

- **Cause**: Previous containers not stopped
- **Solution**:

```bash
# Check running containers
docker ps

# Stop all running containers
docker stop $(docker ps -q)

# Or stop specific container by ID
docker stop CONTAINER_ID
```

#### Problem: `unable to open display` on Linux

- **Cause**: X11 access not granted to Docker or DISPLAY variable not set
- **Solution**:

```bash
# First, ensure DISPLAY is set (especially important when running as root)
export DISPLAY=:0

# Verify DISPLAY is set
echo $DISPLAY
# Should output: :0

# Allow Docker to connect to X11
xhost +local:docker

# Use host networking and mount /home for file access
docker run --rm --platform linux/amd64 \
  --network=host \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v /home:/home \
  -v "$(pwd)/output:/data/output" \
  opera:ui

# After closing, revoke access
xhost -local:docker
```

**Note for root users**: When using `sudo` or switching to root with `su`, the DISPLAY environment variable may not be preserved. Always run `export DISPLAY=:0` before starting the container.

#### Problem: UI exits immediately after "Opening log file" message

- **Cause**: DISPLAY variable not set or X11 permissions issue
- **Solution**:

```bash
# Set DISPLAY variable
export DISPLAY=:0

# Grant X11 access
xhost +local:docker

# Use host networking mode (most reliable)
docker run --rm --platform linux/amd64 \
  --network=host \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v /home:/home \
  -v "$(pwd)/output:/data/output" \
  opera:ui

# Wait 1-2 minutes for the UI to appear
# The "Opening log file" message is normal - MATLAB runtime is initializing
```

#### Problem: Build gets cancelled at installer step

- **Cause**: Insufficient Docker resources or timeout during x86 emulation
- **Solution**:

```bash
# 1. Increase Docker resources in Docker Desktop settings
# 2. Restart Docker Desktop
# 3. Try building again with --no-cache
docker build --no-cache --platform linux/amd64 -f Dockerfile.ui -t opera:ui .
```

### General Issues



#### Problem: Docker daemon not running

- **Solution**:

```bash
# macOS/Windows: Start Docker Desktop application
# Linux: Start Docker service
sudo systemctl start docker
```

#### Problem: Image build takes too long

- **Cause**: Downloading and extracting MATLAB runtime is slow
- **Expected times**:
  - CL version: 5–10 minutes
  - UI version: 10–15 minutes
  - On Apple Silicon with x86 emulation: 15–30 minutes

## Technical Details


### File Structure

```text
OPERA_Docker/
├── Dockerfile                   # Unified Dockerfile for CL, PAR, and UI (auto-downloads installer)
├── build.sh                     # Build script for CL, PAR, UI, or all versions
├── run_opera.sh                 # Wrapper script for CL (Linux/macOS)
├── run_opera_par.sh             # Wrapper script for PAR (Linux/macOS)
├── run_opera_ui.sh              # Wrapper script for UI (Linux/macOS)
├── run_opera.ps1                # Wrapper script for CL (Windows)
├── run_opera_par.ps1            # Wrapper script for PAR (Windows)
├── run_opera_ui.ps1             # Wrapper script for UI (Windows)
└── README.md                    # This file
```

### Build Images

```bash
# CL version
docker build --platform linux/amd64 --build-arg VERSION=cl -t opera:cl .
```

## Quick Reference Commands

### Build Images

```bash
# Using build script (recommended)
./build.sh cl    # Build CL version only
./build.sh par   # Build PAR version only
./build.sh ui    # Build UI version only
./build.sh all   # Build all versions

# Using docker directly
docker build --platform linux/amd64 --build-arg VERSION=cl -t opera:cl .
docker build --platform linux/amd64 --build-arg VERSION=par -t opera:par .
docker build --platform linux/amd64 --build-arg VERSION=ui -t opera:ui .
```

### Useful Docker Commands

```bash
# List images
docker images | grep opera

# List running containers
docker ps

# Stop all containers
docker stop $(docker ps -q)

# Remove image
docker rmi opera:cl
docker rmi opera:par
docker rmi opera:ui

# View container logs
docker logs CONTAINER_ID

# Clean up Docker system
docker system prune -a
```

## Support and Contributing

For issues, questions, or contributions:

- Check this README first
- Search existing issues on GitHub
- Create a new issue with detailed information:
  - Platform (macOS/Linux/Windows)
  - Architecture (x86_64/ARM64)
  - Docker version
  - Complete error messages
  - Steps to reproduce

