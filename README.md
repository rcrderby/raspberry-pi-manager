# Raspberry Pi Manager

[![CI](https://github.com/rcrderby/raspberry-pi-manager/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/rcrderby/raspberry-pi-manager/actions/workflows/ci.yml?query=branch%3Amain)

## Overview

The Ansible automation in this repo provisions and maintains Raspberry Pis that display CRG screens.

### Kiosk/Locked Mode

Each Pi runs Raspberry Pi OS (64-bit) and starts in kiosk mode, where Chromium displays a CRG page full screen without any desktop interaction.  In this mode, the Pi is locked with its boot partition in read-only mode, which allows it to tolerate power losses without corrupting the OS or file system.

In kiosk mode, the Pi accepts commands from a USB keyboard or through a VNC session that tell Chromium to:

- Reload the page (Ctrl+R or F5)
- Zoom in (Ctrl+=)
- Zoom out (Ctrl+-)
- Reset the zoom to 100% (Ctrl+0)

### Unlocked Mode

Unlocking a Pi starts the Raspberry Pi desktop, for maintenance, updates, etc.  In this mode, the Pi will not automatically launch Chromium.

## Getting Started

### Ansible Playbooks

| Playbook | Purpose |
| --- | --- |
| `playbooks/cloud-init.yml` | Writes the network configuration for the SD card of each new Pi |
| `playbooks/maintenance.yml` | Configures, updates, locks, and unlocks Pis |
| `playbooks/site.yml` | Configures unlocked Pis; run by the `maintenance.yml` playbook |

### Environment Setup

The playbooks run from a computer on the same network as the Pis. That network must have internet access to install Pi updates. Run all Ansible commands from the root of the repository.

### Credentials

All Pis share one password for the user `rcr`. Ansible prompts for the password for SSH connectivity, and again for sudo access.

#### Development Container

The development container in `.devcontainer/` has every tool the playbooks need. It requires:

1. Docker
2. The VS Code [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers "VS Code Dev Containers Extension") extension

To use it:

1. Clone and open this repository in VS Code.
2. Run **Dev Containers: Reopen in Container**.
3. Run Ansible commands in the VS Code terminal.

#### Separate Ansible Installation

To run the playbooks without the development container, install Python 3.13 (or later) and `sshpass`, then use these commands to install the required tools and Ansible collections:

```bash
python3 -m venv .venv
```

```bash
source .venv/bin/activate
```

```bash
pip install -r requirements.txt
```

```bash
scripts/install-collections.sh
```

Activate the virtual environment with `source .venv/bin/activate`.

### New Pi Provisioning

To provision several Pis at once, repeat steps 1–6 for each Pi, then run step 7 once.

1. **Add the Pi to the Ansible inventory.** Skip this step for a Pi that is already in the inventory.
   1. Add the hostname to the model group in `inventory/hosts.yml`: `pi5` or `pi4`.
   2. Create `inventory/host_vars/<hostname>.yml` with the Pi's IP address and CRG page.  For example:

      ```yaml
      ---
      network_address: 10.0.40.X
      kiosk_url: http://crg:8000/views/wb/?theme=null
      ```

2. **Create the network configuration file.** This writes `build/cloud-init/<hostname>/network-config` files or every Pi in the inventory:

   ```bash
   ansible-playbook playbooks/cloud-init.yml
   ```

3. **Install the Raspberry Pi Image on the SD card** with [Raspberry Pi Imager](https://www.raspberrypi.com/software/):

   | Setting | Value |
   | --- | --- |
   | Device | Raspberry Pi 5 or Raspberry Pi 4, to match the Pi hardware |
   | Operating system | Raspberry Pi OS (64-bit) |
   | Hostname | The hostname from the inventory, such as `north-wall-pi-1` |
   | User name and password | `rcr` and the shared password |
   | Wi-Fi | None |
   | SSH | Enabled, with password authentication |
   | Raspberry Pi Connect | Disabled |

4. **Copy the network configuration file** to the SD card. Open the `bootfs` volume of the SD card, and replace the default `network-config` file with the `build/cloud-init/<hostname>/network-config` file. Eject the SD card.

5. **Start the Pi.** Insert the SD card, connect the Pi to the network, and connect the display to the HDMI port next to the USB-C power port (HDMI 1); the other HDMI port is disabled. Connect power the Pi to power. After a few minutes, the Pi responds to pings:

   ```bash
   ping -c 1 10.0.40.X
   ```

6. **Remove the old host key** if you're using IP address that was previously in use:

   ```bash
   ssh-keygen -R 10.0.40.X
   ```

7. **Configure and lock the Pi.** Run `maintenance.yml` with the `--limit` parameter and the hostname. To provision several Pis, separate the hostnames with commas, or omit the `--limit` parameter to provision every Pi in the inventory:

   ```bash
   ansible-playbook playbooks/maintenance.yml --ask-pass --ask-become-pass --limit east-bench-pi-1
   ```

   The playbook configures the Pi, upgrades its packages, and locks the OS. The Pi reboots several times during this process.

### Pi Maintenance

Every maintenance task uses the `playbooks/maintenance.yml` playbook. Without the `--limit` parameter, it includes every Pi. To include a subset of Pis, add `--limit` with hostnames separated by commas, or with an inventory group:

```bash
# Perform maintenance on north-wall-pi-1 and main-scoreboard-pi-1
ansible-playbook playbooks/maintenance.yml --ask-pass --ask-become-pass --limit north-wall-pi-1,main-scoreboard-pi-1
```

```bash
# Perform maintenance on all Raspberry Pi 5 devices
ansible-playbook playbooks/maintenance.yml --ask-pass --ask-become-pass --limit pi5
```

| Task | Options | Result |
| --- | --- | --- |
| Update Pis | None | Unlocks, applies inventory settings, upgrades packages, and locks |
| Change a setting, such as `kiosk_url` | None, after editing the inventory | Same as updating the Pis |
| Unlock for work on the desktop | `-e maintenance_mode=unlock` | Reboots into the desktop |
| Lock after work on the desktop | `-e maintenance_mode=lock` | Reboots into kiosk mode |
| Show the lock state | `-e maintenance_mode=lock` | Reports `<hostname> is locked.` and locks any unlocked Pi |
| Replace or re-image an SD card | Not applicable | Follow steps 2–7 of [New Pi Provisioning](#new-pi-provisioning) |

Note: upgrading packages requires internet access.

If Ansible cannot reach one or more Pis, the playbook continues running against any reachable Pis, and will list failures in the `PLAY RECAP`.

`playbooks/site.yml` stops if a Pi is locked, or if its hardware model does not match its model group in the inventory.

## Development

The roles, checks, dependencies, and secrets are described in [docs/development.md](docs/development.md).
