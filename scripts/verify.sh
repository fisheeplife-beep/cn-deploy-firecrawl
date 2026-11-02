#!/usr/bin/env bash
# Convenience: preflight + ghcr probe (+ optional smoke if API up).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/preflight.sh"
"$ROOT/scripts/probe-ghcr.sh" "$ROOT/examples/ghcr-probe.txt"
if curl -fsS --max-time 3 http://127.0.0.1:3002/v0/health/readiness >/dev/null 2>&1; then
  "$ROOT/scripts/smoke.sh"
else
  echo "API not up on 127.0.0.1:3002 — skip smoke (run up-images.sh first)"
fi
