# Raspberry Pi Manager

[![CI](https://github.com/rcrderby/raspberry-pi-manager/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/rcrderby/raspberry-pi-manager/actions/workflows/ci.yml?query=branch%3Amain)

## Overview

The Ansible automation in this repo provisions and maintains Raspberry Pis that display CRG screens.

### Kiosk/Locked Mode

Each Pi runs Raspberry Pi OS (64-bit) and starts in kiosk mode, where Chromium displays a CRG page full screen without any desktop interaction. In this mode, the Pi is locked: its boot partition is read-only, and changes to its root file system are kept in memory and discarded at reboot, which allows it to tolerate power losses without corrupting the OS or file system.

At startup, Chromium shows a countdown, then opens the CRG page once the CRG server responds. If the server does not respond, Chromium shows a countdown to the next attempt.

In kiosk mode, the Pi accepts commands from a USB keyboard or through a VNC session that tell Chromium to:

- Reload the page (`Ctrl` + `R` or `F5`)
- Zoom in (`Ctrl` + `=`)
- Zoom out (`Ctrl` + `-`)
- Reset the zoom to 100% (`Ctrl` + `0`)

### Unlocked Mode

Unlocking a Pi starts the Raspberry Pi desktop, for maintenance, updates, etc. In this mode, the Pi will not automatically launch Chromium.

## Getting Started

### Ansible Playbooks

| Playbook | Purpose |
| --- | --- |
| `playbooks/cloud-init.yml` | Writes the network configuration for the SD card of each new Pi |
| `playbooks/maintenance.yml` | Configures, updates, locks, and unlocks Pis |
| `playbooks/site.yml` | Configures unlocked Pis; run by the `maintenance.yml` playbook |

### Environment Setup

The playbooks run from a computer on the same network as the Pis. Provisioning a new Pi requires Internet access; without it, the playbook stops before making any changes the Pi. During maintenance, a Pi without Internet access skips the package upgrade. Run all Ansible commands from the root of the repository.

#### Credentials

All Pis share one password for the user `rcr`. Ansible prompts for the password for SSH connectivity, and again for sudo access; press Enter at the sudo prompt to use the same password.

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

Activate the virtual environment with `source .venv/bin/activate` in each new terminal.

### New Pi Provisioning

To provision several Pis at once, repeat steps 1–6 for each Pi, then run step 7 once.

1. **Add the Pi to the Ansible inventory.** Skip this step for a Pi that is already in the inventory.
   1. Add the hostname to the model group in `inventory/hosts.yml`: `pi5` or `pi4`.
   2. Create `inventory/host_vars/<hostname>.yml` with the Pi's IP address and CRG page. For example:

      ```yaml
      ---
      network_address: 10.0.40.X
      kiosk_url: http://crg:8000/views/wb/?theme=null
      ```

      A Pi 4 controls a temperature-activated fan connected to GPIO14. For a Pi 4 with other hardware connected to GPIO14, add `pi_config_gpio_fan: false` to this file.

2. **Create the network configuration file.** This writes `build/cloud-init/<hostname>/network-config` files for every Pi in the inventory:

   ```bash
   ansible-playbook playbooks/cloud-init.yml
   ```

3. **Write the Raspberry Pi OS to the SD card** with [Raspberry Pi Imager](https://www.raspberrypi.com/software/):

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

5. **Start the Pi.** Insert the SD card, connect the Pi to the network, and connect the display to the HDMI port next to the USB-C power port (HDMI0); the other HDMI port is disabled. Connect the Pi to power. After a few minutes, the Pi responds to pings:

   ```bash
   ping -c 1 10.0.40.X
   ```

6. **Remove the old host key** if the Pi uses an IP address that was previously in use:

   ```bash
   ssh-keygen -R 10.0.40.X
   ```

7. **Configure and lock the Pi.** Run `maintenance.yml` with the `--limit` parameter and the hostname. To provision several Pis, separate the hostnames with commas, or omit the `--limit` parameter to provision every Pi in the inventory:

   ```bash
   ansible-playbook playbooks/maintenance.yml --ask-pass --ask-become-pass --limit north-wall-pi-1
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
| Update the Pis | None | Unlocks, applies inventory settings, upgrades packages, and locks |
| Change a setting, such as `kiosk_url` | None, after editing the inventory | Same as updating the Pis |
| Unlock for work on the desktop | `-e maintenance_mode=unlock` | Reboots into the desktop |
| Lock after work on the desktop | `-e maintenance_mode=lock` | Removes SSH authorized keys and reboots into kiosk mode |
| Show the lock state | `-e maintenance_mode=status` | Reports `<hostname> is locked.` or `<hostname> is unlocked.` |
| Replace or re-image an SD card | Not applicable | Follow steps 2–7 of [New Pi Provisioning](#new-pi-provisioning) |

Note: a Pi without Internet access skips the package upgrade, and the playbook displays the cause. The other maintenance tasks, including locking, work without Internet access.

Locking a Pi removes its SSH authorized keys, so a key added to an unlocked Pi does not persist. A key added to a locked Pi lasts until the next reboot.

If one or more Pis have configuration failures or cannot be reached, the playbook continues running against the other Pis, and lists any failures in the `PLAY RECAP`. After resolving any problems, run the playbook again with `--limit` and the hostnames of the Pis that reported failures.

`playbooks/site.yml` stops if a Pi is locked, or if its hardware model does not match its model group in the inventory.

## Development

The roles, checks, dependencies, and secrets are described in [docs/development.md](docs/development.md).
