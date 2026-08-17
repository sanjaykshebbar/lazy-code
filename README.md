# Lazy Code

A collection of lightweight setup scripts for **Windows**, **Linux** and **macOS** — plus a
set packaged for **Microsoft Intune** deployment.

Most of the macOS scripts install into your home directory, so they need **no `sudo` and no
Homebrew**. They cut out the manual steps, keep environments consistent, and save setup time.

---

## Before you run anything

These are `curl | shell` one-liners, which means you are executing code straight off the
internet. That is fine for your own repo, but worth doing deliberately:

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-k9s.sh | less
```

Each entry below lists its path so you can find the source quickly. The pipe target
(`bash`, `sh`, `zsh`) is taken from the script's own shebang, so use the command as written.

---

## Scripts

### 🔎 [Searchable index →](https://sanjaykshebbar.github.io/lazy-code/)

Filter-as-you-type across every script, with one-click copy. GitHub strips JavaScript
from rendered markdown, so the live search box lives on a GitHub Pages site rather than
in this file — it is generated from the same source by the same command, so the two
cannot disagree.

Staying here? <kbd>Ctrl</kbd>+<kbd>F</kbd> works fine — every section below is expanded
by default so find-in-page reaches all of it.

<!-- BEGIN:AUTOGEN-SCRIPTS -->

> **39 scripts.** Press <kbd>Ctrl</kbd>+<kbd>F</kbd> (<kbd>⌘</kbd>+<kbd>F</kbd> on macOS) to search this page - every section below is expanded by default so find-in-page reaches it.
>
> This section is generated. Do not edit it by hand - see [Adding a script](#adding-a-script).

<details open>
<summary><h3>&nbsp;Standard Scripts &nbsp;<code>34</code></h3></summary>

<details open>
<summary><b>🐧 Linux</b> &nbsp;<code>5</code></summary>

| Script | What it does | Install |
|:--|:--|:--|
| [`install-clawbot.sh`](Linux/CentOS/install-clawbot.sh) | OpenClaw bot together with Node.js 18 | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Linux/CentOS/install-clawbot.sh \| bash` |
| [`install-kubernetes-master.sh`](Linux/install-kubernetes-master.sh) | Kubernetes control-plane node (Docker, kubeadm, kubelet) | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Linux/install-kubernetes-master.sh \| bash` |
| [`install-maven.sh`](Linux/install-maven.sh) | Apache Maven, plus a JDK if one is missing - no sudo required | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Linux/install-maven.sh \| bash` |
| [`reset-kubernetes.sh`](Linux/reset-kubernetes.sh) | Tear down a kubeadm cluster and clean up residual state | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Linux/reset-kubernetes.sh \| bash` |
| [`setup-ubuntu-host.sh`](Linux/setup-ubuntu-host.sh) | Set the hostname and install an OpenSSH server on Ubuntu | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Linux/setup-ubuntu-host.sh \| bash` |

</details>

<details open>
<summary><b>🍎 macOS</b> &nbsp;<code>28</code></summary>

| Script | What it does | Install |
|:--|:--|:--|
| [`clean-junk.sh`](macOS/clean-junk.sh) | Clear caches, logs and other junk to reclaim disk space | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/clean-junk.sh \| bash` |
| [`install-allure.sh`](macOS/install-allure.sh) | Allure test-reporting CLI (latest GitHub release) | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-allure.sh \| bash` |
| [`install-autoconf.sh`](macOS/install-autoconf.sh) | GNU Autoconf, built from source | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-autoconf.sh \| bash` |
| [`install-claude-code-cli-basic.sh`](macOS/install-claude-code-cli-basic.sh) | Claude Code CLI - simple installer, always the latest build | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-claude-code-cli-basic.sh \| bash` |
| [`install-claude-code-cli.sh`](macOS/install-claude-code-cli.sh) | Claude Code CLI - accepts stable, latest or a pinned version | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-claude-code-cli.sh \| bash` |
| [`install-cocoapods.sh`](macOS/install-cocoapods.sh) | CocoaPods dependency manager, with its own private Ruby | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-cocoapods.sh \| bash` |
| [`install-dbt.sh`](macOS/install-dbt.sh) | dbt (data build tool) CLI | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-dbt.sh \| bash` |
| [`install-fvm.sh`](macOS/install-fvm.sh) | Flutter Version Management (FVM) plus a bundled Dart SDK | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-fvm.sh \| bash` |
| [`install-gnupg.sh`](macOS/install-gnupg.sh) | GnuPG, built from source | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-gnupg.sh \| bash` |
| [`install-go.sh`](macOS/install-go.sh) | Go toolchain - resolves the current release automatically | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-go.sh \| bash` |
| [`install-helm.sh`](macOS/install-helm.sh) | Helm, the Kubernetes package manager | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-helm.sh \| sh` |
| [`install-hugo.sh`](macOS/install-hugo.sh) | Hugo static site generator (latest GitHub release) | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-hugo.sh \| bash` |
| [`install-intellij-idea-ce.sh`](macOS/install-intellij-idea-ce.sh) | IntelliJ IDEA Community Edition, with a choice of versions | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-intellij-idea-ce.sh \| bash` |
| [`install-jmeter.sh`](macOS/install-jmeter.sh) | Apache JMeter on macOS - no sudo, no Homebrew, with a Java check | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-jmeter.sh \| bash` |
| [`install-k9s.sh`](macOS/install-k9s.sh) | k9s, the Kubernetes terminal UI | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-k9s.sh \| zsh` |
| [`install-maven-mvnd.sh`](macOS/install-maven-mvnd.sh) | Maven Daemon (mvnd), the faster Maven front-end | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-maven-mvnd.sh \| sh` |
| [`install-minikube-amd64.sh`](macOS/install-minikube-amd64.sh) | Minikube for Intel Macs | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-minikube-amd64.sh \| bash` |
| [`install-minikube-arm64.sh`](macOS/install-minikube-arm64.sh) | Minikube for Apple Silicon Macs | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-minikube-arm64.sh \| bash` |
| [`install-nvm.sh`](macOS/install-nvm.sh) | nvm, the Node Version Manager | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-nvm.sh \| bash` |
| [`install-postgresql.sh`](macOS/install-postgresql.sh) | PostgreSQL binaries | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-postgresql.sh \| bash` |
| [`install-redis.sh`](macOS/install-redis.sh) | Redis, built from source | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-redis.sh \| bash` |
| [`install-teleport-v14-arm64.sh`](macOS/install-teleport-v14-arm64.sh) | Teleport v14 client (tsh) for Apple Silicon | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-teleport-v14-arm64.sh \| bash` |
| [`install-teleport-v14.sh`](macOS/install-teleport-v14.sh) | Teleport v14 client (tsh), architecture auto-detected | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-teleport-v14.sh \| bash` |
| [`install-terraform.sh`](macOS/install-terraform.sh) | Terraform - resolves the current release automatically | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-terraform.sh \| bash` |
| [`install-cocoapods-verbose.sh`](macOS/scripts_with_logs/install-cocoapods-verbose.sh) | CocoaPods install with full step-by-step logging | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/scripts_with_logs/install-cocoapods-verbose.sh \| bash` |
| [`collect-network-usage.sh`](macOS/troubleshooting/collect-network-usage.sh) | Sample per-process network usage over time | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/troubleshooting/collect-network-usage.sh \| bash` |
| [`generate-network-report.sh`](macOS/troubleshooting/generate-network-report.sh) | Collect a macOS network diagnostic report | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/troubleshooting/generate-network-report.sh \| bash` |
| [`generate-report.py`](macOS/troubleshooting/generate-report.py) | Render collected diagnostics into a readable report | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/troubleshooting/generate-report.py -o report.py && python3 report.py` |

</details>

<details open>
<summary><b>🐳 Docker</b> &nbsp;<code>1</code></summary>

| Script | What it does | Install |
|:--|:--|:--|
| [`install.sh`](DockerFiles/Guacomole/install.sh) | Apache Guacamole remote-desktop gateway via Docker Compose | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/DockerFiles/Guacomole/install.sh \| bash` |

</details>

</details>

<details open>
<summary><h3>&nbsp;Intune Based Scripts &nbsp;<code>5</code></h3></summary>

Packaged for deployment through Microsoft Intune. These run as root in the Intune agent's context, not as the signed-in user.

<details open>
<summary><b>🍎 macOS</b> &nbsp;<code>5</code></summary>

| Script | What it does | Install |
|:--|:--|:--|
| [`install-cocoapods.sh`](Intune/macOS/install-cocoapods.sh) | CocoaPods with a self-contained Ruby, packaged for Intune | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/install-cocoapods.sh \| bash` |
| [`install-colima.sh`](Intune/macOS/install-colima.sh) | Colima container runtime, packaged for Intune | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/install-colima.sh \| bash` |
| [`install-fvm.sh`](Intune/macOS/install-fvm.sh) | FVM and Flutter tooling, packaged for Intune | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/install-fvm.sh \| zsh` |
| [`install-postman.sh`](Intune/macOS/install-postman.sh) | Postman desktop app, packaged for Intune | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/install-postman.sh \| bash` |
| [`uninstall-rize-io.sh`](Intune/macOS/uninstall-rize-io.sh) | Remove the Rize.io app and all of its leftover data | `curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/uninstall-rize-io.sh \| bash` |

</details>

</details>

> **Windows:** no standard scripts yet. Drop a `.ps1` into `Windows/`
> with a `# Description:` line and it will appear here automatically.

<!-- END:AUTOGEN-SCRIPTS -->

---

## SentinelOps agent

The `SentinelOps/` directory is **not** part of the script collection above. It is the
distribution point for the SentinelOps endpoint agent — real machines fetch and execute
those paths as SYSTEM/root, so the layout there is deliberately frozen.

See [SentinelOps/README.md](SentinelOps/README.md).

---

## Adding a script

The tables above are generated. You do not edit them.

1. Drop your script into the right folder:

   | Folder | For |
   |---|---|
   | `Windows/` | Standard Windows scripts (`.ps1`) |
   | `Linux/` | Standard Linux scripts |
   | `macOS/` | Standard macOS scripts |
   | `Intune/macOS/` | macOS scripts packaged for Intune |
   | `Intune/Windows/` | Windows scripts packaged for Intune |

2. Give it a shebang and a description header:

   ```bash
   #!/usr/bin/env bash
   # Description: Install the thing, without sudo
   # Platform: macOS
   ```

3. Commit and push. A GitHub Action regenerates this README and commits the result.

If the `# Description:` line is missing, the generator falls back to a name derived from the
filename — so the script still gets listed, just with a worse label.

To preview the change locally before pushing:

```bash
python scripts/generate_readme.py
```

---

## Repository layout

```
Windows/          Standard Windows scripts
Linux/            Standard Linux scripts
macOS/            Standard macOS scripts
  troubleshooting/    Diagnostic collectors
  scripts_with_logs/  Verbose-logging variants
Intune/           Scripts packaged for Microsoft Intune
DockerFiles/      Docker Compose stacks
SentinelOps/      Endpoint agent distribution (frozen paths)
archive/          Superseded scripts, kept for reference
scripts/          Repo tooling (README generator)
```

### Moved paths

Scripts were reorganised into the platform folders above. The old paths still work —
each one now holds a small stub that forwards to the new location and prints a notice.
The stubs are a compatibility shim, not scripts; update your bookmarks when convenient.
