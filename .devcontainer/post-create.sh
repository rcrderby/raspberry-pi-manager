#!/usr/bin/env bash
# Runs once after the development container is created.
set -euo pipefail

scripts/install-collections.sh
pre-commit install --install-hooks
