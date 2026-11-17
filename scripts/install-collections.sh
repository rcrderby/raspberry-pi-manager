#!/usr/bin/env bash
# Installs the Ansible collections in requirements.yml. Retries when the download fails.
set -euo pipefail
cd "$(dirname "$0")/.."

attempts=3
for attempt in $(seq "$attempts"); do
  if ansible-galaxy collection install --requirements-file requirements.yml --collections-path collections; then
    exit 0
  fi
  if [ "$attempt" -lt "$attempts" ]; then
    echo "Attempt $attempt of $attempts failed. Retrying in 30 seconds." >&2
    sleep 30
  fi
done
exit 1
