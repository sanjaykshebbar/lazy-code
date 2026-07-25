<#
  SentinelOps Agent -- one-line installer (Windows).
  Hosted at: https://github.com/sanjaykshebbar/lazy-code/tree/main/SentinelOps

  Run in an ELEVATED PowerShell:
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/install.ps1))) -Server "<server-url>" -Token "<enrollment-token>"

  Downloads the standalone SentinelOps agent (a single static binary -- no Node.js,
  no package manager, no other runtime dependency of any kind) and installs it as a
  Windows Service under LocalSystem. The binary's own `install` command handles
  enrollment and verification; this script's job is the preflight checks below,
  fetching the binary, and handing off.
#>
param(
  [Parameter(Mandatory = $true)][string]$Server,
  [Parameter(Mandatory = $true)][string]$Token
)
$ErrorActionPreference = "Stop"

# ---- preflight: fail fast with a clear message, before downloading anything ----

# Installing a Windows Service requires local Administrator rights. Without this
# check, the failure happens deep inside the agent binary's service-manager call
# with a much less obvious error, well after the download.
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  Write-Error "This installer must run in an ELEVATED PowerShell (Run as Administrator) -- installing a Windows Service requires it."
  exit 1
}

# PowerShell 5.1's default TLS is too old for GitHub's raw-content host; without
# this, Invoke-WebRequest below fails with an opaque "could not create SSL/TLS
# secure channel" error on older Windows.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$Dest = Join-Path $env:ProgramData "SentinelOps"
$AlreadyEnrolled = Test-Path (Join-Path $Dest "agent.json")
if ($AlreadyEnrolled) {
  Write-Host "Existing installation detected at $Dest -- this will update the binary and re-verify enrollment in place (same device identity, not a new one)."
}

# ---- fetch + install ----

$BinUrl = if ($env:SO_BIN_URL) { $env:SO_BIN_URL } else { "https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/bin/windows-amd64/sentinelops-agent.exe" }

# Download to a TEMP path, not directly into $Dest: on an upgrade, the running
# service already has sentinelops-agent.exe open, and Windows won't let anything
# (including this download) write over a locked file. The binary's own `install`
# command stops the service before it replaces that file, so handing it a
# separately-downloaded copy avoids the lock entirely.
$TmpBin = Join-Path $env:TEMP "sentinelops-agent-$([guid]::NewGuid().ToString('N')).exe"

Write-Host "Downloading agent from $BinUrl ..."
Invoke-WebRequest -UseBasicParsing -Uri $BinUrl -OutFile $TmpBin

try {
  & $TmpBin install -server $Server -token $Token
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Install failed -- see the message above, or check $Dest\agent.log"
    exit 1
  }
} finally {
  Remove-Item -Path $TmpBin -Force -ErrorAction SilentlyContinue
}
