<#
.SYNOPSIS
Wrapper script for OPERA Docker container on Windows PowerShell.
Usage: .\run_opera.ps1 -s <file> [options]
#>

$ErrorActionPreference = "Stop"
$Image = "opera:cl"

# Function to show help
function Show-Help {
    docker run --rm --platform linux/amd64 $Image -h
}

# Check for help flag
if ($args -contains "-h" -or $args -contains "--help") {
    Show-Help
    exit 0
}

# Initialize variables
$InputFile = $null
$HasStd = $false

# Parse arguments to find input file and detect flags
for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = $args[$i]

    # Check for input file flags
    if ($arg -match "^-(s|SDF|MOL|SMI|d|Descriptors|Mat|ascii|i|MolID|t|SaltInfo|l|Labels)$" -or $arg -in @("-s", "--SDF", "--MOL", "--SMI", "-d", "--Descriptors", "--Mat", "--ascii", "-i", "--MolID", "-t", "--SaltInfo", "-l", "--Labels")) {
        if (($i + 1) -lt $args.Count) {
            if (-not $InputFile) { $InputFile = $args[$i+1] }
        }
    }

    # Ambiguous -m flag (Model list vs Matlab input)
    if ($arg -eq "-m") {
        if (($i + 1) -lt $args.Count) {
             $NextArg = $args[$i+1]
             # If next arg is a file, treat as input
             if (Test-Path $NextArg -PathType Leaf) {
                  if (-not $InputFile) { $InputFile = $NextArg }
             }
        }
    }

    # Check for standardization flag
    if ($arg -match "^-(st|Standardize)$" -or $arg -in @("-st", "--Standardize")) {
        $HasStd = $true
    }
}

# Legacy check: if no input flag, but first arg is a file
if (-not $InputFile -and $args.Count -gt 0 -and -not ($args[0].StartsWith("-"))) {
    if (Test-Path $args[0]) {
        $InputFile = $args[0]
    }
}

$DockerArgs = @("run", "--rm", "--platform", "linux/amd64")

if ($InputFile) {
    $AbsFile = Resolve-Path $InputFile
    $InputDir = Split-Path $AbsFile -Parent
    $FileName = Split-Path $AbsFile -Leaf

    # Mount input directory
    $DockerArgs += "-v"
    $DockerArgs += "$($InputDir):/data"
    $DockerArgs += "-w"
    $DockerArgs += "/data"

    # Workaround for KNIME internal path issue (-st flag)
    $TmpDir = $null
    if ($HasStd) {
        $TmpDir = Join-Path $PWD ".opera_tmp_$(Get-Random)"
        New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null
        Copy-Item $AbsFile -Destination (Join-Path $TmpDir "input.sdf")

        $DockerArgs += "-v"
        $DockerArgs += "$($TmpDir):/root/Sample_input"
    }

    # Reconstruct arguments replacing the host path with the container path
    $FinalArgs = @()
    $SkipNext = $false

    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($SkipNext) { $SkipNext = $false; continue }

        $arg = $args[$i]

        # Check if this arg is a file in the mounted directory
        $IsMountedFile = $false
        if (Test-Path $arg -ErrorAction SilentlyContinue) {
             $ArgAbs = (Resolve-Path $arg).Path
             $ArgDir = Split-Path $ArgAbs -Parent
             if ($ArgDir -eq $InputDir) {
                  $IsMountedFile = $true
                  $ArgFileName = Split-Path $ArgAbs -Leaf
             }
        }

        if ($IsMountedFile) {
             # Replace strict files with container path
             $FinalArgs += "/data/$ArgFileName"
        } elseif ($arg -match "^-(s|SDF|MOL|SMI|d|Descriptors|Mat|ascii|i|MolID|t|SaltInfo|l|Labels)$") {
             # Pass standard input flags as is
             $FinalArgs += $arg
        } else {
             $FinalArgs += $arg
        }
    }

    if (-not $InputFile) {
        $FileName = "Input"
    }

    Write-Host "Running OPERA on $FileName..."

    # Run Docker
    & docker $DockerArgs $Image $FinalArgs

    # Cleanup
    if ($TmpDir) {
        Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
    }
} else {
    # No file, just pass args (version, help, etc)
    & docker $DockerArgs $Image $args
}
