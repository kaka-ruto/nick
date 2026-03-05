# VPS Installation Guide for Cafaye

Cafaye is optimized for remote development on a VPS (Virtual Private Server). This guide covers how to set up your remote forge on a fresh Linux instance.

## 📋 Prerequisites

- **VPS**: Ubuntu 22.04, 24.04 or Debian 12 (recommended)
- **RAM**: 2GB+ (Minimum 1GB with swap)
- **Disk**: 20GB+
- **Access**: Root access via SSH

## 🚀 One-Command Install

The fastest way to install Cafaye on a fresh VPS is to run the automated installer:

```bash
# SSH into your VPS as root
ssh root@<your-vps-ip>

# Run the installer
curl -fsSL https://raw.githubusercontent.com/cafaye/cafaye/master/install.sh | bash
```

### What the installer does:
1. **Detects Environment**: Identifies your OS and hardware.
2. **Installs Dependencies**: Packages like `git`, `curl`, `jq`, and `gum`.
3. **Installs Nix**: Uses the Determinate Systems Nix installer.
4. **Bootstraps Cafaye**: Clones the repo to `~/.config/cafaye`.
5. **Interactive Setup**: Prompts for your Git identity, theme, and tools.
6. **Hardens Security**: Configures the SSH daemon and firewall for safety.

---

## 🔐 Secure Access (Tailscale)

If you plan to use multiple nodes, we highly recommend enabling **Tailscale** during installation.

1. Generate an **Auth Key** at [tailscale.com](https://login.tailscale.com/admin/settings/keys).
2. Paste the key when prompted by the installer.
3. Your VPS will join your private Tailnet, allowing you to access it via its private IP (e.g., `100.x.y.z`) without opening public SSH ports.

---

## 🛠 Manual Installation (Advanced)

If you prefer to configure before installing:

```bash
# 1. Clone the repo
git clone https://github.com/cafaye/cafaye.git ~/.config/cafaye
cd ~/.config/cafaye

# 2. Configure your state
# Edit the state files manually if desired
vi environment.json
vi settings.json

# 3. Run the installer script
./install.sh
```

---

## 🏠 Managing Your VPS

Once installed, use the `caf` command to manage your environment:

```bash
# View system status
caf status

# Install new language stacks
caf install rails
caf install rust

# Rebuild and apply changes
caf apply

# Check Factory (CI/CD) status
caf ci status --latest
```

## 📡 Three-Layer Monitoring (Recommended)

For low-cost VPS reliability, use all three layers:

1. **Layer 1 (dashboard):** Install Netdata for real-time host metrics.
2. **Layer 2 (alerts):** Use Cafaye's built-in periodic health alerts.
3. **Layer 3 (external):** Add UptimeRobot/Better Stack checks from outside your VPS.

### Layer 2: Cafaye Alerts (Easy Setup)

```bash
# Interactive setup (provider optional: none, telegram, discord, slack)
caf-vps-monitor-setup

# Apply system changes (enables timer when monitoring is enabled)
caf-system-rebuild

# Send a test notification
caf-vps-monitor-check --notify-test
```

What Cafaye monitors by default:
- RAM usage (%)
- Disk usage on `/` (%)
- CPU load per core
- Critical processes/services you define

Useful health checks:

```bash
# Verify monitor timer and last run
caf-system-doctor

# Run one immediate check
caf-vps-monitor-check
```

---

## 🏗 Fleet Integration

If you have Cafaye on both your local laptop and your VPS, you can sync them:

```bash
# From your local machine, view the fleet
caf fleet status

# Sync your local configuration to the VPS
caf fleet sync

# Apply the local configuration remotely
caf fleet apply
```

---

## 🏥 Troubleshooting

### Logs
All installation and rebuild logs are stored in:
`~/.config/cafaye/logs/`

### System Check
Run the diagnostic doctor to find common issues:
```bash
caf doctor
```

### Re-running Setup
If you want to re-run the interactive setup wizard:
```bash
caf-setup
```
