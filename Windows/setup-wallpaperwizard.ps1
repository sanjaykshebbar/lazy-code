# Description: Enable OpenSSH and advertise the WallpaperWizard Windows discovery marker.
# Run once in an elevated Windows PowerShell. The script contains no credentials.
$ErrorActionPreference = 'Stop'
$activity = 'WallpaperWizard Windows setup'
$discoveryMarker = 'WW_WINDOWS_SHA256_7bd18925be67c4757a7dd7c9d4143179a406acd51120ae404b03a8c5d7daa69a'

function Show-WallpaperWizardStep {
    param([int]$Number, [string]$Message)
    Write-Host ("[{0}/4] {1}" -f $Number, $Message) -ForegroundColor Cyan
    Write-Progress -Activity $activity -Status $Message -PercentComplete (($Number - 1) * 25)
}

function Set-WallpaperWizardDiscoveryMarker {
    param([string]$Marker)

    $config = Join-Path $env:ProgramData 'ssh\sshd_config'
    $sshd = Join-Path $env:WINDIR 'System32\OpenSSH\sshd.exe'
    if (-not (Test-Path -LiteralPath $sshd -PathType Leaf)) {
        $sshd = (Get-Command sshd.exe -ErrorAction Stop).Source
    }
    if (-not (Test-Path -LiteralPath $config -PathType Leaf)) {
        throw 'OpenSSH did not create its default configuration. Ask your Windows administrator to review the sshd service.'
    }

    $effective = & $sshd -T -f $config
    if ($LASTEXITCODE -ne 0) { throw 'Could not read the active SSH configuration.' }
    $line = $effective | Where-Object { $_ -match '^versionaddendum\s+' } | Select-Object -First 1
    $addendum = ([string]$line -replace '^versionaddendum\s+', '').Trim()
    if (($addendum -split '\s+') -ccontains $Marker) { return }

    $setting = if ($addendum -and $addendum -ne 'none') { "$Marker $addendum" } else { $Marker }
    $candidate = "$config.wallpaperwizard-$([Guid]::NewGuid().ToString('N'))"
    $backup = "$candidate.bak"
    try {
        $original = [IO.File]::ReadAllText($config)
        $updated = "# WallpaperWizard discovery`r`nVersionAddendum $setting`r`n`r`n$original"
        [IO.File]::WriteAllText($candidate, $updated, [Text.UTF8Encoding]::new($false))
        Set-Acl -LiteralPath $candidate -AclObject (Get-Acl -LiteralPath $config)
        & $sshd -t -f $candidate
        if ($LASTEXITCODE -ne 0) { throw 'SSH rejected the proposed discovery setting. Check the sshd configuration.' }
        [IO.File]::Replace($candidate, $config, $backup)
        try {
            Restart-Service -Name sshd
        } catch {
            [IO.File]::WriteAllBytes($config, [IO.File]::ReadAllBytes($backup))
            Start-Service -Name sshd -ErrorAction SilentlyContinue
            throw
        }
        Remove-Item -LiteralPath $backup -ErrorAction SilentlyContinue
    } finally {
        Remove-Item -LiteralPath $candidate -ErrorAction SilentlyContinue
    }
}

Write-Host $activity -ForegroundColor Cyan
Write-Host 'This prepares the PC for wallpaper management over SSH.'

try {
    Show-WallpaperWizardStep 1 'Checking administrator access'
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Open Windows PowerShell with Run as administrator, then run the setup command again.'
    }

    Show-WallpaperWizardStep 2 'Checking the OpenSSH Server feature'
    $feature = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' | Select-Object -First 1
    if (-not $feature) { throw 'OpenSSH Server is unavailable. Check Windows Optional Features or ask your Windows administrator.' }
    if ($feature.State -ne 'Installed') {
        Write-Host 'Installing OpenSSH Server. Windows may take several minutes to download the feature.'
        $install = Add-WindowsCapability -Online -Name $feature.Name
        if ($install.RestartNeeded) { throw 'Restart Windows to finish installing OpenSSH Server, then run this setup again.' }
    } else {
        Write-Host 'OpenSSH Server is already installed.'
    }

    Show-WallpaperWizardStep 3 'Starting OpenSSH Server and checking the firewall rule'
    Set-Service -Name sshd -StartupType Automatic
    Start-Service -Name sshd
    $rule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
    if ($rule) {
        $rule | Set-NetFirewallRule -Enabled True
    } else {
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
          -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Domain,Private | Out-Null
    }
    Write-Host 'Windows must allow TCP port 22 from your WallpaperWizard server on the active network profile.'

    Show-WallpaperWizardStep 4 'Configuring the Windows discovery marker and verifying SSH'
    Set-WallpaperWizardDiscoveryMarker -Marker $discoveryMarker
    if ((Get-Service -Name sshd).Status -ne 'Running') {
        throw 'OpenSSH Server did not start. Check the sshd service in Windows Services.'
    }

    Write-Host ''
    Write-Host 'Windows setup complete.' -ForegroundColor Green
    Write-Host "Discovery marker: $discoveryMarker"
    Write-Host '1. In Dashboard > Push Settings, add this PC address or its network range and save.'
    Write-Host '2. Confirm the device administrator credentials are saved before pushing wallpapers.'
    Write-Host '3. In Dashboard > Devices, select Scan now and approve this PC.'
} catch {
    Write-Host ("Setup stopped. {0}" -f $_.Exception.Message) -ForegroundColor Red
    throw
} finally {
    Write-Progress -Activity $activity -Completed
}
