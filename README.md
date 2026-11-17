# Raspberry Pi Manager

Ansible-based automation to build and maintain Raspberry Pi devices for CRG displays.

## Development Environment

A development container is available and defined in `.devcontainer/`, and it requires:

1. Docker
2. The VS Code [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers "VS Code Dev Containers Extension") extension.

To use the development container:

1. Open the repository in VS Code.
2. Run **Dev Containers: Reopen in Container**.

After the container is created, `.devcontainer/post-create.sh` installs the appropriate Ansible collections and the pre-commit hooks.

Named volumes hold the Ansible collections (`collections/`), the pre-commit hook environments, and `~/.ssh`, so they persist
across container rebuilds.

## Inventory

`inventory/hosts.yml` lists the Pis in the `raspberry_pis` group, with child groups by model (`pi5`, `pi4`).

| File | Contents |
| --- | --- |
| `inventory/group_vars/raspberry_pis.yml` | Settings shared by all Pis |
| `inventory/group_vars/pi5.yml`, `pi4.yml` | Model-specific settings |
| `inventory/host_vars/<host>.yml` | Per-Pi settings, including IPv4 |

To add a Pi, add it to a model group in `inventory/hosts.yml` and create its `host_vars` file.

## New Pi

1. Write Raspberry Pi OS (64-bit) to the SD card with Raspberry Pi Imager, with the hostname, the user `rcr` with a
   password, and SSH with password authentication.
2. Write the cloud-init network configuration for each Pi:

   ```bash
   ansible-playbook playbooks/cloud-init.yml
   ```

3. Copy `build/cloud-init/<host>/network-config` to the `bootfs` partition of the SD card, replacing the existing file.
4. Boot the Pi.

## Running playbooks

Playbooks run in the development container. Ansible prompts for the SSH password and the sudo password; the sudo prompt
defaults to the SSH password.

```bash
ansible-playbook playbooks/site.yml --ask-pass --ask-become-pass
```

`site.yml` stops if a Pi's hardware model does not match its inventory group, or if the Pi is locked.

Ansible saves the host key of a Pi on first connection and refuses a changed host key. After a Pi is reimaged, remove its
old host key:

```bash
ssh-keygen -R <address>
```

## Roles

Each role documents its variables in `meta/argument_specs.yml`.

| Role | Configures |
| --- | --- |
| `base` | Hostname, `/etc/hosts`, locale, time zone, console keyboard, journal size; disables cloud-init |
| `network` | Static IPv4 address of the wired interface, in a Netplan file in the format NetworkManager writes |
| `pi_config` | Wi-Fi and Bluetooth disabled (device tree overlays), second HDMI port disabled, SSH and VNC enabled |
| `desktop` | Wallpaper, desktop shortcuts, and keyboard layout of the desktop session |
| `kiosk` | Kiosk session: labwc with its own configuration and Chromium only, restarted if it exits; keys that exit kiosk mode do nothing, and the mouse pointer is hidden until the mouse moves. Chromium policies, and passwords stored without a keyring |

Changes that need a reboot, such as network changes, reboot the Pi at the end of the play. The `network` role fails if
the new address differs from the current address of the interface, unless `network_allow_address_change` is `true`.

## Checks

The pre-commit hooks run on every commit. To run them manually on every file in the repository:

```bash
pre-commit run --all-files
```

CI (`.github/workflows/ci.yml`) runs the same hooks in the development container image, and scans the full git history
for secrets with gitleaks.

## Dependencies

| File | Contents | Updated by |
| --- | --- | --- |
| `requirements.in` | Python tools | Dependabot |
| `requirements.txt` | Python tools and their dependencies, with hashes, compiled from `requirements.in` | Dependabot |
| `requirements.yml` | Ansible collections | Manually |
| `.devcontainer/Dockerfile` | Base image, pinned by digest | Dependabot |
| `.pre-commit-config.yaml` | pre-commit hooks | Dependabot |
| `.github/workflows/*.yml` | GitHub Actions, pinned by commit SHA | Dependabot |

To compile `requirements.txt` after changing `requirements.in`, run this command in the development container:

```bash
pip-compile --allow-unsafe --generate-hashes --strip-extras requirements.in
```

Afterward, rebuild the container.

## Secrets

Files named `vault*.yml` or `vault*.yaml` must be encrypted with Ansible Vault. The vault password is not stored in the repository.

## License

[Apache License 2.0](LICENSE)
