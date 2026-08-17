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

<!-- BEGIN:AUTOGEN-SCRIPTS -->

> 39 scripts, generated automatically from the repository.
> Do not edit this section by hand - see [Adding a script](#adding-a-script).

<details open>
<summary><h3>&nbsp;Standard Scripts &nbsp;<code>34</code></h3></summary>

<details>
<summary><b>🐧 Linux</b> &nbsp;<code>5</code></summary>

**OpenClaw bot together with Node.js 18**

`Linux/CentOS/install-clawbot.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Linux/CentOS/install-clawbot.sh | bash
```

**Kubernetes control-plane node (Docker, kubeadm, kubelet)**

`Linux/install-kubernetes-master.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Linux/install-kubernetes-master.sh | bash
```

**Apache Maven, plus a JDK if one is missing - no sudo required**

`Linux/install-maven.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Linux/install-maven.sh | bash
```

**Tear down a kubeadm cluster and clean up residual state**

`Linux/reset-kubernetes.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Linux/reset-kubernetes.sh | bash
```

**Set the hostname and install an OpenSSH server on Ubuntu**

`Linux/setup-ubuntu-host.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Linux/setup-ubuntu-host.sh | bash
```

</details>

<details>
<summary><b>🍎 macOS</b> &nbsp;<code>28</code></summary>

**Clear caches, logs and other junk to reclaim disk space**

`macOS/clean-junk.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/clean-junk.sh | bash
```

**Allure test-reporting CLI (latest GitHub release)**

`macOS/install-allure.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-allure.sh | bash
```

**GNU Autoconf, built from source**

`macOS/install-autoconf.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-autoconf.sh | bash
```

**Claude Code CLI - simple installer, always the latest build**

`macOS/install-claude-code-cli-basic.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-claude-code-cli-basic.sh | bash
```

**Claude Code CLI - accepts stable, latest or a pinned version**

`macOS/install-claude-code-cli.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-claude-code-cli.sh | bash
```

**CocoaPods dependency manager, with its own private Ruby**

`macOS/install-cocoapods.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-cocoapods.sh | bash
```

**dbt (data build tool) CLI**

`macOS/install-dbt.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-dbt.sh | bash
```

**Flutter Version Management (FVM) plus a bundled Dart SDK**

`macOS/install-fvm.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-fvm.sh | bash
```

**GnuPG, built from source**

`macOS/install-gnupg.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-gnupg.sh | bash
```

**Go toolchain - resolves the current release automatically**

`macOS/install-go.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-go.sh | bash
```

**Helm, the Kubernetes package manager**

`macOS/install-helm.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-helm.sh | sh
```

**Hugo static site generator (latest GitHub release)**

`macOS/install-hugo.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-hugo.sh | bash
```

**IntelliJ IDEA Community Edition, with a choice of versions**

`macOS/install-intellij-idea-ce.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-intellij-idea-ce.sh | bash
```

**Apache JMeter on macOS - no sudo, no Homebrew, with a Java check**

`macOS/install-jmeter.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-jmeter.sh | bash
```

**k9s, the Kubernetes terminal UI**

`macOS/install-k9s.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-k9s.sh | zsh
```

**Maven Daemon (mvnd), the faster Maven front-end**

`macOS/install-maven-mvnd.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-maven-mvnd.sh | sh
```

**Minikube for Intel Macs**

`macOS/install-minikube-amd64.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-minikube-amd64.sh | bash
```

**Minikube for Apple Silicon Macs**

`macOS/install-minikube-arm64.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-minikube-arm64.sh | bash
```

**nvm, the Node Version Manager**

`macOS/install-nvm.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-nvm.sh | bash
```

**PostgreSQL binaries**

`macOS/install-postgresql.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-postgresql.sh | bash
```

**Redis, built from source**

`macOS/install-redis.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-redis.sh | bash
```

**Teleport v14 client (tsh) for Apple Silicon**

`macOS/install-teleport-v14-arm64.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-teleport-v14-arm64.sh | bash
```

**Teleport v14 client (tsh), architecture auto-detected**

`macOS/install-teleport-v14.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-teleport-v14.sh | bash
```

**Terraform - resolves the current release automatically**

`macOS/install-terraform.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/install-terraform.sh | bash
```

**CocoaPods install with full step-by-step logging**

`macOS/scripts_with_logs/install-cocoapods-verbose.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/scripts_with_logs/install-cocoapods-verbose.sh | bash
```

**Sample per-process network usage over time**

`macOS/troubleshooting/collect-network-usage.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/troubleshooting/collect-network-usage.sh | bash
```

**Collect a macOS network diagnostic report**

`macOS/troubleshooting/generate-network-report.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/troubleshooting/generate-network-report.sh | bash
```

**Render collected diagnostics into a readable report**

`macOS/troubleshooting/generate-report.py`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/macOS/troubleshooting/generate-report.py -o report.py && python3 report.py
```

</details>

<details>
<summary><b>🐳 Docker</b> &nbsp;<code>1</code></summary>

**Apache Guacamole remote-desktop gateway via Docker Compose**

`DockerFiles/Guacomole/install.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/DockerFiles/Guacomole/install.sh | bash
```

</details>

</details>

<details open>
<summary><h3>&nbsp;Intune Based Scripts &nbsp;<code>5</code></h3></summary>

Packaged for deployment through Microsoft Intune. These run as root in the Intune agent's context, not as the signed-in user.

<details>
<summary><b>🍎 macOS</b> &nbsp;<code>5</code></summary>

**CocoaPods with a self-contained Ruby, packaged for Intune**

`Intune/macOS/install-cocoapods.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/install-cocoapods.sh | bash
```

**Colima container runtime, packaged for Intune**

`Intune/macOS/install-colima.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/install-colima.sh | bash
```

**FVM and Flutter tooling, packaged for Intune**

`Intune/macOS/install-fvm.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/install-fvm.sh | zsh
```

**Postman desktop app, packaged for Intune**

`Intune/macOS/install-postman.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/install-postman.sh | bash
```

**Remove the Rize.io app and all of its leftover data**

`Intune/macOS/uninstall-rize-io.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Intune/macOS/uninstall-rize-io.sh | bash
```

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
