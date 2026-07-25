<#
  SentinelOps PC Agent — one-line installer (Windows).
  Hosted at: https://github.com/sanjaykshebbar/lazy-code/tree/main/SentinelOps

  Run in an ELEVATED PowerShell:
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/install.ps1))) -Server "<server-url>" -Token "<enrollment-token>"
#>
param(
  [Parameter(Mandatory = $true)][string]$Server,
  [Parameter(Mandatory = $true)][string]$Token
)
$ErrorActionPreference = "Stop"
# Windows PowerShell 5.1 defaults to old TLS; GitHub requires TLS 1.2.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
$Server   = $Server.TrimEnd('/')
$TaskName = "SentinelOpsAgent"
$AgentUrl = if ($env:SO_AGENT_URL) { $env:SO_AGENT_URL } else { "https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/agent.mjs" }

$node = (Get-Command node -ErrorAction SilentlyContinue)
if (-not $node) { Write-Error "Node.js 18+ is required on this machine (https://nodejs.org)."; return }
$NodePath = $node.Source

$Dest    = Join-Path $env:ProgramData "SentinelOps"
$Agent   = Join-Path $Dest "agent.mjs"
$Config  = Join-Path $Dest "agent.json"
$LogPath = Join-Path $Dest "agent.log"
$RunCmd  = Join-Path $Dest "run-agent.cmd"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

Write-Host "Downloading agent from $AgentUrl ..."
Invoke-WebRequest -UseBasicParsing -Uri $AgentUrl -OutFile $Agent

@{ serverUrl = $Server; enrollToken = $Token } | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $Config

@"
@echo off
set SO_CONFIG=$Config
set SO_LOG=$LogPath
"$NodePath" "$Agent"
"@ | Set-Content -Encoding ASCII -Path $RunCmd

$action    = New-ScheduledTaskAction -Execute $RunCmd
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -StartWhenAvailable -RestartCount 999 `
              -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) `
              -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName
Write-Host "SentinelOps Agent installed and started (Task: $TaskName). Log: $LogPath"
