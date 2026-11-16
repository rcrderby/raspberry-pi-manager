# raspberry-pi-manager

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
