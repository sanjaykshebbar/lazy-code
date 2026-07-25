<#
  SentinelOps Agent -- one-line installer (Windows).
  Hosted at: https://github.com/sanjaykshebbar/lazy-code/tree/main/SentinelOps

  Run in an ELEVATED PowerShell:
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/install.ps1))) -Server "<server-url>" -Token "<enrollment-token>"

  Downloads the standalone SentinelOps agent (a single static binary -- no Node.js or
  any other runtime required) and installs it as a Windows Service under LocalSystem.
  The binary's own `install` command handles enrollment and verification; this
  script just fetches it and hands off.
#>
param(
  [Parameter(Mandatory = $true)][string]$Server,
  [Parameter(Mandatory = $true)][string]$Token
)
$ErrorActionPreference = "Stop"
# Windows PowerShell 5.1 defaults to old TLS; GitHub requires TLS 1.2.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$BinUrl = if ($env:SO_BIN_URL) { $env:SO_BIN_URL } else { "https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/bin/windows-amd64/sentinelops-agent.exe" }

$Dest = Join-Path $env:ProgramData "SentinelOps"
$Bin  = Join-Path $Dest "sentinelops-agent.exe"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

Write-Host "Downloading agent from $BinUrl ..."
Invoke-WebRequest -UseBasicParsing -Uri $BinUrl -OutFile $Bin

& $Bin install -server $Server -token $Token
if ($LASTEXITCODE -ne 0) {
  Write-Error "Install failed -- see the message above, or check $Dest\agent.log"
  exit 1
}
