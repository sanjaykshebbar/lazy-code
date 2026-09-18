#Requires -RunAsAdministrator
<#
.SYNOPSIS
    New device provisioning script — OOBE bypass prep, local accounts,
    hostname, core app installs, and Windows Update.

.DESCRIPTION
    Intended for use during imaging / audit mode / first-run provisioning
    on Windows 10/11 endpoints. Run elevated (as Administrator).

    Sections:
      1. OOBE bypass (Microsoft-account requirement skip)
      2. Local account creation (x2)
      3. Hostname configuration
      4. App installs via winget (Chrome, Teams, DisplayLink)
      5. Windows Update trigger

.NOTES
    - Some actions (hostname change, OOBE registry keys) require a reboot
      to take effect.
    - Run this in an elevated PowerShell session (5.1 or 7+).
    - Tested assumption: winget is present (default on current Win10/11
      images with App Installer). If not present, install App Installer
      from the Microsoft Store or via Add-AppxPackage first.
#>

[CmdletBinding()]
param(
    # --- Hostname ---
    [string]$NewHostname = "ZETA-PC-0001",

    # --- Local accounts: edit these before running ---
    [string]$Account1Name = "zeta.admin",
    [securestring]$Account1Password = (ConvertTo-SecureString "ChangeMe123!" -AsPlainText -Force),
    [switch]$Account1IsAdmin = $true,

    [string]$Account2Name = "zeta.user",
    [securestring]$Account2Password = (ConvertTo-SecureString "ChangeMe456!" -AsPlainText -Force),
    [switch]$Account2IsAdmin = $false,

    # --- DisplayLink fallback download (used if no winget package found) ---
    [string]$DisplayLinkDownloadUrl = "https://www.synaptics.com/products/displaylink-graphics/downloads/windows",

    # --- Toggle Windows Update install (installs updates + can trigger reboot) ---
    [switch]$InstallWindowsUpdates = $true
)

$ErrorActionPreference = "Stop"
$logPath = "$env:ProgramData\ProvisionLog"
New-Item -ItemType Directory -Path $logPath -Force | Out-Null
Start-Transcript -Path "$logPath\provision-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" -Append

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# 1. OOBE BYPASS — skip Microsoft account requirement so local accounts
#    can be created at first logon. (Full OOBE skip needs an unattend.xml
#    / audit-mode answer file — this handles the MSA-requirement piece,
#    which is the part scriptable post-image.)
# ---------------------------------------------------------------------------
function Set-OobeBypass {
    Write-Step "Configuring OOBE bypass (local account allowance)"

    $oobePath = "HKLM:\SYSTEM\Setup\OOBE"
    if (-not (Test-Path $oobePath)) {
        New-Item -Path $oobePath -Force | Out-Null
    }
    New-ItemProperty -Path $oobePath -Name "BypassNRO" -PropertyType DWORD -Value 1 -Force | Out-Null

    # Also disable the "Privacy experience" / consent screens some builds show
    $privacyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE"
    if (-not (Test-Path $privacyPath)) {
        New-Item -Path $privacyPath -Force | Out-Null
    }
    New-ItemProperty -Path $privacyPath -Name "DisablePrivacyExperience" -PropertyType DWORD -Value 1 -Force | Out-Null

    Write-Host "OOBE bypass registry keys set. Takes effect on next OOBE pass / after Sysprep." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 2. LOCAL ACCOUNTS
# ---------------------------------------------------------------------------
function New-ProvisionLocalUser {
    param(
        [string]$Name,
        [securestring]$Password,
        [bool]$IsAdmin
    )

    if (Get-LocalUser -Name $Name -ErrorAction SilentlyContinue) {
        Write-Host "User '$Name' already exists — skipping creation." -ForegroundColor Yellow
        return
    }

    New-LocalUser -Name $Name `
        -Password $Password `
        -PasswordNeverExpires:$true `
        -AccountNeverExpires `
        -FullName $Name `
        -Description "Provisioned by Setup-NewDevice.ps1" | Out-Null

    $groupName = if ($IsAdmin) { "Administrators" } else { "Users" }
    Add-LocalGroupMember -Group $groupName -Member $Name

    Write-Host "Created local account '$Name' (member of '$groupName')." -ForegroundColor Green
}

function New-LocalAccounts {
    Write-Step "Creating local accounts"
    New-ProvisionLocalUser -Name $Account1Name -Password $Account1Password -IsAdmin $Account1IsAdmin
    New-ProvisionLocalUser -Name $Account2Name -Password $Account2Password -IsAdmin $Account2IsAdmin
}

# ---------------------------------------------------------------------------
# 3. HOSTNAME
# ---------------------------------------------------------------------------
function Set-DeviceHostname {
    Write-Step "Setting hostname to '$NewHostname'"

    if ($env:COMPUTERNAME -eq $NewHostname) {
        Write-Host "Hostname already set to '$NewHostname' — skipping." -ForegroundColor Yellow
        return
    }

    Rename-Computer -NewName $NewHostname -Force -ErrorAction Stop
    Write-Host "Hostname will be '$NewHostname' after next reboot." -ForegroundColor Green
    $script:RebootRequired = $true
}

# ---------------------------------------------------------------------------
# 4. APP INSTALLS (winget)
# ---------------------------------------------------------------------------
function Test-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget not found. Install 'App Installer' from the Microsoft Store or provision it via Add-AppxPackage before running this script."
    }
}

function Install-WingetApp {
    param(
        [string]$Id,
        [string]$FriendlyName
    )
    Write-Host "Installing $FriendlyName ($Id)..."
    try {
        winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements
        Write-Host "$FriendlyName installed." -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to install $FriendlyName via winget: $_"
    }
}

function Install-CoreApps {
    Write-Step "Installing core applications"
    Test-Winget

    Install-WingetApp -Id "Google.Chrome" -FriendlyName "Google Chrome"
    Install-WingetApp -Id "Microsoft.Teams" -FriendlyName "Microsoft Teams"

    # DisplayLink: try winget first (package availability varies by region/version),
    # fall back to a direct-download placeholder you should point at your
    # internal repo / the vendor's direct driver URL for your hardware model.
    Write-Host "Installing DisplayLink driver..."
    $displayLinkInstalled = $false
    try {
        winget install --id "DisplayLink.GraphicsDriver" --exact --silent --accept-package-agreements --accept-source-agreements
        $displayLinkInstalled = $true
        Write-Host "DisplayLink driver installed via winget." -ForegroundColor Green
    }
    catch {
        Write-Warning "winget package for DisplayLink not found or failed. Falling back to direct download."
    }

    if (-not $displayLinkInstalled) {
        try {
            $dlPath = "$env:TEMP\DisplayLinkSetup.exe"
            Write-Host "Downloading DisplayLink installer from $DisplayLinkDownloadUrl ..."
            Invoke-WebRequest -Uri $DisplayLinkDownloadUrl -OutFile $dlPath -UseBasicParsing
            Start-Process -FilePath $dlPath -ArgumentList "/S" -Wait
            Write-Host "DisplayLink driver installed via direct download." -ForegroundColor Green
        }
        catch {
            Write-Warning "DisplayLink driver install failed: $_. Update `$DisplayLinkDownloadUrl to point at your model-specific installer/share."
        }
    }
}

# ---------------------------------------------------------------------------
# 5. WINDOWS UPDATE
# ---------------------------------------------------------------------------
function Invoke-WindowsUpdate {
    Write-Step "Triggering Windows Update"

    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "Installing PSWindowsUpdate module..."
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
    }

    Import-Module PSWindowsUpdate

    Write-Host "Scanning for and installing updates (this can take a while)..."
    Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$false -Verbose
    Write-Host "Windows Update pass complete. Check log for details; a reboot may be pending." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
$script:RebootRequired = $false

Set-OobeBypass
New-LocalAccounts
Set-DeviceHostname
Install-CoreApps

if ($InstallWindowsUpdates) {
    Invoke-WindowsUpdate
}

Write-Step "Provisioning complete"
if ($script:RebootRequired) {
    Write-Host "A reboot is required (hostname change / OOBE keys). Reboot when ready." -ForegroundColor Yellow
}

Stop-Transcript
