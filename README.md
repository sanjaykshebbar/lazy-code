# Lazy Code

Lazy Code is a collection of simple scripts to help with quick installation and environment setup, primarily focused on **Ubuntu distributions** and **Mac systems**.

---

## 🟢 **I. Initial Setup for Ubuntu**

To quickly set up a fresh Ubuntu environment, run the following command:

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/refs/heads/main/setup.sh | sudo sh
```
---
🔵 II. Reset Kubernetes Cluster on Ubuntu
If you need to reset your Kubernetes cluster, use this script:

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/refs/heads/main/reset_kubernetes.sh | sudo sh
```
---
🟠 III. Set Up Kubernetes on Ubuntu
For setting up Kubernetes on Ubuntu, run the following command:

```bash
curl -fsSL https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/refs/heads/main/kubernetes-deployment-master.sh | sudo sh
```
---

🟡 IV. Install Homebrew on Mac (Non-Sudo Version)
If you're using a Mac and prefer not to use sudo for installing Homebrew, execute the following:

```bash
curl https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/refs/heads/main/non-sudo-brew.sh | sh
```
📝 Note:
Make sure Xcode CLI tools are manually installed before running the script above.
---
🟣 V. Clean Up Basic Junk on Mac
To clear up some basic junk files on your Mac, you can use this cleanup script:

```bash
curl https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/refs/heads/main/Mac/Cleaning-junk.sh | sh
```





