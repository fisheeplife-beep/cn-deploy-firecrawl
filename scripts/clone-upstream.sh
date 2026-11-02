#!/usr/bin/env bash
# Shallow clone upstream Firecrawl at a pinned tag.
set -euo pipefail
TAG="${FIRECRAWL_TAG:-v2.11.162}"
DEST="${FIRECRAWL_DEST:-data/upstream-firecrawl}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/data"
if [[ -d "$ROOT/$DEST/.git" ]]; then
  echo "Already cloned: $ROOT/$DEST"
  exit 0
fi
git clone --depth 1 --branch "$TAG" https://github.com/firecrawl/firecrawl.git "$ROOT/$DEST"
echo "OK $TAG → $ROOT/$DEST"
