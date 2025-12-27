# Charm CLI Installer for Windows
# Usage: irm https://raw.githubusercontent.com/divyanshu-parihar/charm-cli/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$REPO = "divyanshu-parihar/charm-cli"
$BINARY_NAME = "charm.exe"

# Default install directory (user-level, no admin required)
$INSTALL_DIR = "$env:LOCALAPPDATA\charm-cli"

function Write-Banner {
    Write-Host ""
    Write-Host "   ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗" -ForegroundColor Cyan
    Write-Host "  ██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║" -ForegroundColor Cyan
    Write-Host "  ██║     ███████║███████║██████╔╝██╔████╔██║" -ForegroundColor Cyan
    Write-Host "  ██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║" -ForegroundColor Cyan
    Write-Host "  ╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║" -ForegroundColor Cyan
    Write-Host "   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Charm CLI Installer for Windows" -ForegroundColor Green
    Write-Host ""
}

function Get-Platform {
    $arch = if ([Environment]::Is64BitOperatingSystem) {
        if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_IDENTIFIER -match "ARM") {
            "arm64"
        } else {
            "amd64"
        }
    } else {
        Write-Host "32-bit systems are not supported" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Platform: windows-$arch" -ForegroundColor Yellow
    return $arch
}

function Get-LatestRelease {
    param([string]$Arch)
    
    Write-Host "Fetching latest release..." -ForegroundColor Yellow
    
    $latestUrl = "https://api.github.com/repos/$REPO/releases/latest"
    
    try {
        $headers = @{
            "User-Agent" = "Charm-CLI-Installer"
        }
        $releaseInfo = Invoke-RestMethod -Uri $latestUrl -Headers $headers
        
        # Find the Windows asset for our architecture
        $assetName = "charm-windows-$Arch.exe"
        $asset = $releaseInfo.assets | Where-Object { $_.name -eq $assetName }
        
        if (-not $asset) {
            # Try without .exe extension
            $assetName = "charm-windows-$Arch"
            $asset = $releaseInfo.assets | Where-Object { $_.name -eq $assetName }
        }
        
        if (-not $asset) {
            Write-Host "Could not find release for windows-$Arch" -ForegroundColor Red
            Write-Host ""
            Write-Host "Available assets:" -ForegroundColor Yellow
            $releaseInfo.assets | ForEach-Object { Write-Host "  - $($_.name)" }
            exit 1
        }
        
        $version = $releaseInfo.tag_name
        Write-Host "Found: $version" -ForegroundColor Green
        
        return @{
            Url = $asset.browser_download_url
            Version = $version
        }
    }
    catch {
        Write-Host "Failed to fetch release information: $_" -ForegroundColor Red
        exit 1
    }
}

function Install-Charm {
    param(
        [string]$DownloadUrl
    )
    
    Write-Host "Downloading Charm CLI..." -ForegroundColor Yellow
    
    # Create install directory if it doesn't exist
    if (-not (Test-Path $INSTALL_DIR)) {
        New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
    }
    
    $installPath = Join-Path $INSTALL_DIR $BINARY_NAME
    
    try {
        # Download the binary
        $tempFile = [System.IO.Path]::GetTempFileName()
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $tempFile -UseBasicParsing
        
        # Move to install directory
        Move-Item -Path $tempFile -Destination $installPath -Force
        
        Write-Host "Installed to: $installPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to download or install: $_" -ForegroundColor Red
        exit 1
    }
}

function Add-ToPath {
    # Check if already in PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($currentPath -notlike "*$INSTALL_DIR*") {
        Write-Host "Adding $INSTALL_DIR to PATH..." -ForegroundColor Yellow
        
        $newPath = "$currentPath;$INSTALL_DIR"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        
        # Also update current session
        $env:PATH = "$env:PATH;$INSTALL_DIR"
        
        Write-Host "Added to user PATH" -ForegroundColor Green
    } else {
        Write-Host "Already in PATH" -ForegroundColor Green
    }
}

function Test-Installation {
    $charmPath = Join-Path $INSTALL_DIR $BINARY_NAME
    
    if (Test-Path $charmPath) {
        Write-Host ""
        Write-Host "✓ Charm CLI installed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Run 'charm --help' to get started." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "NOTE: You may need to restart your terminal for PATH changes to take effect." -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "Installation may have failed. Please check $INSTALL_DIR" -ForegroundColor Red
    }
}

function Main {
    Write-Banner
    
    $arch = Get-Platform
    $release = Get-LatestRelease -Arch $arch
    Install-Charm -DownloadUrl $release.Url
    Add-ToPath
    Test-Installation
}

# Run the installer
Main
