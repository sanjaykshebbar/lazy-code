# SentinelOps Agent installers

One-line install scripts for the SentinelOps endpoint agent — a single static
binary, no runtime dependency (no Node.js, no anything) on the managed machine.
Replace `<SERVER>` with your SentinelOps URL and `<TOKEN>` with the enrollment
token from **Integrations → SentinelOps PC Agent**.

### Windows (elevated PowerShell)
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/install.ps1))) -Server "<SERVER>" -Token "<TOKEN>"
```
Installs as a Windows Service (`SentinelOpsAgent`) running as LocalSystem, with
automatic restart on failure.

### macOS (sudo)
```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/SentinelOps/install.sh | sudo bash -s -- <SERVER> <TOKEN>
```
Installs as a launchd daemon (`com.sentinelops.agent`) running as root.

### Linux
Not yet supported by this installer — the agent's service-installation code for
Linux isn't implemented yet (`apps/endpoint-agent/internal/service/service_other.go`
in the main repo). Track progress there.

## What the installer does

Downloads the prebuilt agent binary for your platform from `bin/<platform>/`
below, then runs its own `install -server <SERVER> -token <TOKEN>` command, which:
writes state to a machine-local, permission-restricted config file; generates and
seals an Ed25519 device keypair (DPAPI on Windows, machine-bound AES-GCM on macOS)
— there is no shared long-lived credential; registers the background service; and
waits to confirm the device actually enrolled before reporting success (rather
than declaring victory the moment the service is registered).

Once enrolled, the agent reports posture (hardware, OS, encryption/AV/firewall,
network, installed software) on a recurring check-in, and executes only actions
from its own compiled-in catalog — diagnostics, application install/update
(`.msi` / `.pkg` / `.dmg`), reboot, hostname change, on-screen notifications, and
updating itself. Software installs are **simulated** (downloaded and validated,
not executed) unless the deploying server explicitly enables real installs.

## Files

- `install.ps1`, `install.sh` — the installers above.
- `bin/<platform>/sentinelops-agent[.exe]` — prebuilt binaries, rebuilt and
  committed here from `apps/endpoint-agent` in the main SentinelOps repo whenever
  the agent changes. There's no build step on the endpoint.

## Updating the binaries

From `apps/endpoint-agent` in the SentinelOps repo:
```bash
GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o path/to/lazy-code/SentinelOps/bin/windows-amd64/sentinelops-agent.exe ./cmd/sentinelops-agent
GOOS=darwin  GOARCH=arm64 go build -trimpath -ldflags="-s -w" -o path/to/lazy-code/SentinelOps/bin/darwin-arm64/sentinelops-agent   ./cmd/sentinelops-agent
GOOS=darwin  GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o path/to/lazy-code/SentinelOps/bin/darwin-amd64/sentinelops-agent   ./cmd/sentinelops-agent
```
Commit and push. Already-enrolled devices keep running the old binary until an
admin triggers **Update agent** on them from the device detail page (or reinstalls
manually) — pushing here doesn't reach anything automatically. Note the bootstrap
gap: a device has to already be running a build that *has* the update action (this
one, 0.3.0+) before it can use it — a device stuck on something older needs one
manual reinstall to cross that line, same as before.
