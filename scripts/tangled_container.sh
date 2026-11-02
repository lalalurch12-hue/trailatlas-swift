#!/usr/bin/env bash
set -euo pipefail
cd /workspace
cleanup() {
  rm -f .runtime/tangled-write-key
  if [[ -d .build ]]; then
    chown -R "${TRAILATLAS_CACHE_UID:?}:${TRAILATLAS_CACHE_GID:?}" .build
  fi
}
trap cleanup EXIT
apt-get update
apt-get install -y --no-install-recommends pkg-config zlib1g-dev curl python3 git openssh-client
swift --version
if [[ "${TANGLED_PIPELINE_KIND:-}" != "schedule" ]]; then
  bash scripts/pruefen.sh
fi
swift build -c release --jobs 2
if [[ "${TANGLED_PIPELINE_KIND:-}" != "schedule" ]]; then
  python3 tests/http_checks.py --binary .build/release/TrailAtlas
  python3 tests/card_checks.py --binary .build/release/TrailAtlas
fi
: "${TRAILATLAS_PUSH_KEY_B64:?Missing Tangled public-data write credential}"
: "${TANGLED_PUSH_URL:?Missing Tangled push remote}"
umask 077
mkdir -p .runtime
python3 - <<'KEY'
import base64, os
from pathlib import Path
key = base64.b64decode(os.environ['TRAILATLAS_PUSH_KEY_B64'], validate=True)
assert key.startswith(b'-----BEGIN OPENSSH PRIVATE KEY-----\n')
Path('.runtime/tangled-write-key').write_bytes(key)
KEY
unset TRAILATLAS_PUSH_KEY_B64
export GIT_SSH_COMMAND='ssh -i /workspace/.runtime/tangled-write-key -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/workspace/.tangled/ssh_known_hosts'
git config --global --add safe.directory /workspace
git config --global --add safe.directory /workspace/.data-worktree
git remote set-url --push origin "$TANGLED_PUSH_URL"
export TRAILATLAS_BOT_EMAIL='trailatlas-refresh@lalalurch.tngl.sh'
bash scripts/refresh_public_data.sh
