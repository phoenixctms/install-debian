#!/bin/bash

set -euo pipefail

# Typically invoked as a normal user (same as /ctsms/update); elevate once.
if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

KEY="${CTSMS_CONFIG_SSH_KEY:-${1:-/root/.ssh/ctsms_config_deploy}}"
KEY_DIR=$(dirname "$KEY")
PUB="${KEY}.pub"
# Always use root's standard known_hosts so clone (StrictHostKeyChecking=yes) finds it.
SSH_DIR=/root/.ssh
KNOWN_HOSTS="${SSH_DIR}/known_hosts"

# Published github.com host keys:
# https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
GITHUB_HOST_KEYS='github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk='

EXPECTED_FPS=(
  'SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU' # Ed25519
  'SHA256:p2QAMXNIC1TJYWeIOttrVc98/R1BUFWu3/LiyKgUfQM' # ECDSA
  'SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s' # RSA
)

if ! command -v ssh-keygen >/dev/null 2>&1; then
  apt-get -q -y -o=Dpkg::Use-Pty=0 install openssh-client
fi

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
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

# Verify pinned keys match GitHub's published fingerprints, then install them.
TMP_KEYS=$(mktemp)
trap 'rm -f "$TMP_KEYS"' EXIT
printf '%s\n' "$GITHUB_HOST_KEYS" >"$TMP_KEYS"
for expected in "${EXPECTED_FPS[@]}"; do
  if ! ssh-keygen -lf "$TMP_KEYS" | grep -Fq "$expected"; then
    echo "ERROR: Pinned github.com host key does not match published fingerprint $expected" >&2
    echo "Refusing to update $KNOWN_HOSTS. See GitHub SSH key fingerprints docs." >&2
    exit 1
  fi
done

if grep -qE '^github\.com[ ,]' "$KNOWN_HOSTS" 2>/dev/null; then
  echo "github.com already present in $KNOWN_HOSTS"
else
  echo "Adding verified github.com host keys to $KNOWN_HOSTS"
  cat "$TMP_KEYS" >>"$KNOWN_HOSTS"
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
