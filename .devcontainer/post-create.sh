#!/usr/bin/env bash
# Runs once after the development container is created.
set -euo pipefail

ansible-galaxy collection install --requirements-file requirements.yml --collections-path collections
pre-commit install --install-hooks
