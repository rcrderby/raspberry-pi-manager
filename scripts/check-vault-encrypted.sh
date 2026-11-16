#!/usr/bin/env bash
# Fails if any file passed to it is not Ansible Vault-encrypted.
set -euo pipefail

status=0
for f in "$@"; do
  if ! head -n 1 "$f" | grep -q '^[$]ANSIBLE_VAULT;'; then
    echo "ERROR: $f is not encrypted. Run: ansible-vault encrypt $f" >&2
    status=1
  fi
done
exit "$status"
