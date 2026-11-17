# Development

## Development Container

After the container is created, `.devcontainer/post-create.sh` installs the Ansible collections and the pre-commit hooks. Named volumes hold the Ansible collections (`collections/`), the pre-commit hook environments, and `~/.ssh`, so they persist across container rebuilds.

## Inventory

`inventory/hosts.yml` lists the Pis in the `raspberry_pis` group, with child groups by model (`pi5`, `pi4`).

| File | Contents |
| --- | --- |
| `inventory/group_vars/raspberry_pis.yml` | Settings shared by all Pis |
| `inventory/group_vars/pi5.yml`, `pi4.yml` | Model-specific settings |
| `inventory/host_vars/<host>.yml` | Per-Pi settings, including IPv4 |

## Roles

Each role documents its variables in `meta/argument_specs.yml`.

| Role | Configures |
| --- | --- |
| `base` | Hostname, `/etc/hosts`, locale, time zone, console keyboard, journal size; disables cloud-init |
| `network` | Static IPv4 address of the wired interface, in a Netplan file in the format NetworkManager uses |
| `pi_config` | Wi-Fi and Bluetooth disabled (device tree overlays), second HDMI port disabled, SSH and VNC enabled |
| `desktop` | Wallpaper, desktop shortcuts, and keyboard layout of the desktop session |
| `kiosk` | Kiosk session: labwc with its own configuration and Chromium only, restarted if it exits; a start page that counts down, then opens the CRG page once the CRG server responds; ignores key combinations that exit kiosk mode, and the mouse pointer is hidden until the mouse moves. Chromium policies, and passwords stored without a keyring |
| `readonly_os` | `overlayroot` package; lock, unlock, and status steps used by `maintenance.yml` |

Changes that need a reboot, such as network changes, reboot the Pi at the end of the play. The `network` role fails if the new address differs from the current address of the interface, unless `network_allow_address_change` is `true`.

## Checks

The pre-commit hooks run on every commit. To run them manually on every file in the repository:

```bash
pre-commit run --all-files
```

CI (`.github/workflows/ci.yml`) runs the same hooks in the development container image, and scans the full git history for secrets with gitleaks.

CI also runs the Molecule scenario in `molecule/default/`. It runs `site.yml` in a Debian Trixie container with systemd, runs it again to check that nothing changes, and checks the resulting files. Tasks that need Raspberry Pi hardware are tagged `molecule-notest` and skipped; locking and unlocking are tested on hardware only. To run the scenario, Molecule needs access to a Docker daemon:

```bash
molecule test
```

## Dependencies

| File | Contents | Updated by |
| --- | --- | --- |
| `requirements.in` | Python tools | Dependabot |
| `requirements.txt` | Python tools and their dependencies, with hashes, compiled from `requirements.in` | Dependabot |
| `requirements.yml` | Ansible collections | Manually |
| `.devcontainer/Dockerfile`, `molecule/default/Dockerfile` | Base images, pinned by digest | Dependabot |
| `.pre-commit-config.yaml` | pre-commit hooks | Dependabot |
| `.github/workflows/*.yml` | GitHub Actions, pinned by commit SHA | Dependabot |

To compile `requirements.txt` after changing `requirements.in`, run this command in the development container:

```bash
pip-compile --allow-unsafe --generate-hashes --strip-extras requirements.in
```

Afterward, rebuild the container.

## Secrets

Files named `vault*.yml` or `vault*.yaml` must be encrypted with Ansible Vault. The vault password is not stored in the repository.
