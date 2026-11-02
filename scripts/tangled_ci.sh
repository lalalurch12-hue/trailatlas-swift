#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$TASK_ROOT"
docker run --rm --network host \
  -v "$TASK_ROOT:/workspace" -w /workspace \
  -e TRAILATLAS_CONTAINER=1 \
  -e TANGLED_PIPELINE_KIND -e TANGLED_PUSH_URL -e TRAILATLAS_PUSH_KEY_B64 \
  swift:6.2-noble@sha256:e508ef1e4be68087f720de622b91cbf1e32799a7aa96134b35e6f1a1d656db7a \
  bash scripts/tangled_container.sh
