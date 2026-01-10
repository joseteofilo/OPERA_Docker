<#
.SYNOPSIS
Wrapper script for launching OPERA UI (GUI) on Windows PowerShell.
Usage: .\run_opera_ui.ps1
#>

$ErrorActionPreference = "Stop"
$Image = "opera:ui"

Write-Host "Starting OPERA UI for Windows..."
Write-Host ""
Write-Host "NOTE: You must have an X11 Server like VcXsrv installed and running!"
Write-Host "      If you haven't, install VcXsrv (https://sourceforge.net/projects/vcxsrv/)"
Write-Host "      and launch it with 'Disable access control' checked."
Write-Host ""

# Attempt to find the correct IP for the X Server
# In standard Docker Desktop for Windows, host.docker.internal works best.
# In WSL2, we might need the nameserver IP.

$DisplayHost = "host.docker.internal"

# Try to check if we are in a WSL environment or standard Windows
if ($IsLinux) {
    # If running inside WSL Powershell (rare but possible) or similar
    # Using nameserver approach
    $DisplayHost = (cat /etc/resolv.conf | grep nameserver | awk '{print $2}').Trim()
}

Write-Host "Using Display Host: $DisplayHost"
Write-Host "Mapping Users directory to /mnt/users for file access."

# Create output dir
New-Item -ItemType Directory -Force -Path "output" | Out-Null

$DockerArgs = @(
    "run", "--rm", "--platform", "linux/amd64",
    "-e", "DISPLAY=$($DisplayHost):0.0",
    "-e", "LIBGL_ALWAYS_INDIRECT=1",
    "-v", "C:\Users:/mnt/users",
    "-v", "$($PWD):/data/host",
    "-w", "/data/host"
)

# Run Docker
Write-Host "Launching Container..."
& docker $DockerArgs $Image

Write-Host "OPERA UI Closed."
