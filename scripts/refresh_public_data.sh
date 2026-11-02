#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# The checkout belongs to the runner UID; the Swift container runs as root.
# Trust only this checkout and its own data worktree.
if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  git config --global --add safe.directory "$TASK_ROOT"
  git config --global --add safe.directory "$TASK_ROOT/.data-worktree"
fi
git -C "$TASK_ROOT" rev-parse --show-toplevel >/dev/null
cd "$TASK_ROOT"
mkdir -p .runtime .public-data
if git fetch origin trailatlas-data; then
  git show FETCH_HEAD:public-state.json > .runtime/state.json
  git show FETCH_HEAD:tracking-discovery.json > .runtime/tracking-discovery.json
  git worktree add --detach .data-worktree FETCH_HEAD
else
  git worktree add --detach .data-worktree HEAD
  git -C .data-worktree checkout --orphan trailatlas-data
  git -C .data-worktree rm -r --cached .
fi
DATA_DIR="$TASK_ROOT/.runtime" PUBLIC_DATA_DIR="$TASK_ROOT/.public-data" .build/release/TrailAtlas --refresh
python3 - <<'CHECK_PUBLIC'
import json
from pathlib import Path
public=json.loads(Path('.public-data/public-state.json').read_text())
assert public.get('sessions') == {}, 'Refusing to publish private sessions'
CHECK_PUBLIC
cp .public-data/public-state.json .public-data/tracking-discovery.json .data-worktree/
git -C .data-worktree config user.name 'TrailAtlas source refresher'
git -C .data-worktree config user.email 'trailatlas-refresh@users.noreply.github.com'
git -C .data-worktree add public-state.json tracking-discovery.json
if ! git -C .data-worktree diff --cached --quiet; then
  git -C .data-worktree commit -m 'Refresh public race dates and timing sources'
  git -C .data-worktree push origin HEAD:refs/heads/trailatlas-data
fi
