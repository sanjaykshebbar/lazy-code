# SentinelOps PC Agent installers

One-line install scripts for the SentinelOps PC Agent (Windows / macOS / Linux).
Requires Node.js 18+ on the endpoint. Replace `<SERVER>` with your SentinelOps URL
and `<TOKEN>` with the enrollment token from **Integrations → SentinelOps PC Agent**.

### macOS / Linux
```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/install.sh | sudo bash -s -- <SERVER> <TOKEN>
```

### Windows (elevated PowerShell)
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/install.ps1))) -Server "<SERVER>" -Token "<TOKEN>"
```

The installer downloads `agent.mjs` (hosted alongside these scripts), writes the
server URL + token to a protected config file, and registers a background service
(systemd / launchd / Scheduled Task) that enrols the device, reports posture &
inventory, and applies approved installs. Installs are simulated unless
`SO_REAL_INSTALL=1`.

Files: `install.sh`, `install.ps1`, `agent.mjs` (the agent bundle).
