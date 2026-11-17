#!/bin/bash

set -euo pipefail

# Typically invoked as a normal user (same as /ctsms/update); elevate once.
if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

KEY="${CTSMS_CONFIG_SSH_KEY:-${1:-/root/.ssh/ctsms_config_deploy}}"
KEY_DIR=$(dirname "$KEY")
PUB="${KEY}.pub"
KNOWN_HOSTS="${KEY_DIR}/known_hosts"

if ! command -v ssh-keygen >/dev/null 2>&1 || ! command -v ssh-keyscan >/dev/null 2>&1; then
  apt-get -q -y -o=Dpkg::Use-Pty=0 install openssh-client
fi

mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"

if [ -f "$KEY" ]; then
  echo "Deploy key already exists at $KEY (leaving it unchanged)."
else
  HOST=$(hostname -f 2>/dev/null || hostname)
  ssh-keygen -t ed25519 -f "$KEY" -N '' -C "ctsms-config-deploy@${HOST}"
fi

chmod 600 "$KEY"
if [ -f "$PUB" ]; then
  chmod 644 "$PUB"
fi
chown root:root "$KEY" "$PUB" 2>/dev/null || true

touch "$KNOWN_HOSTS"
chmod 644 "$KNOWN_HOSTS"
if ! grep -qE '^github\.com[ ,]' "$KNOWN_HOSTS" 2>/dev/null; then
  echo "Adding github.com host keys to $KNOWN_HOSTS"
  ssh-keyscan -t rsa,ecdsa,ed25519 github.com >>"$KNOWN_HOSTS" 2>/dev/null
else
  echo "github.com already present in $KNOWN_HOSTS"
fi

echo
echo "Public key ($PUB):"
echo "--------"
cat "$PUB"
echo "--------"
echo
echo "Next steps:"
echo "  1. Open the private config repo on GitHub → Settings → Deploy keys → Add deploy key"
echo "  2. Title: e.g. $(hostname -f 2>/dev/null || hostname)"
echo "  3. Paste the public key above"
echo "  4. Leave \"Allow write access\" unchecked (read-only)"
echo "  5. Install/upgrade without a TOKEN, e.g.:"
echo "       /ctsms/update master OWNER/config-repo"
echo "     (passing a TOKEN still uses the old PAT download mode)"
