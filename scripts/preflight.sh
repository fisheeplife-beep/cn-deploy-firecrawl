#!/usr/bin/env bash
# Preflight for Firecrawl CN self-host lab.
set -euo pipefail

ok=0; warn=0; bad=0
say() { printf '%s\n' "$*"; }
pass() { say "✅ $*"; ok=$((ok+1)); }
warn_() { say "⚠️  $*"; warn=$((warn+1)); }
fail() { say "❌ $*"; bad=$((bad+1)); }

say "=== Firecrawl CN preflight ==="
say ""
say "Host: $(uname -s) $(uname -m)"

for t in curl git; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t present"; else fail "$t missing"; fi
done

if command -v docker >/dev/null 2>&1; then
  pass "docker: $(docker --version 2>/dev/null | head -1)"
  if docker compose version >/dev/null 2>&1; then
    pass "docker compose: $(docker compose version 2>/dev/null | head -1)"
  else
    fail "docker compose v2 missing (need docker compose)"
  fi
  if docker info >/dev/null 2>&1; then
    pass "docker daemon reachable"
  else
    warn_ "docker daemon not reachable (pull/up will fail until fixed)"
  fi
else
  fail "docker missing — required for self-host paths"
fi

if command -v python3 >/dev/null 2>&1; then pass "python3 present (probe-ghcr)"; else warn_ "python3 missing — probe-ghcr.sh needs it"; fi

if df -Pk . >/dev/null 2>&1; then
  avail_kb=$(df -Pk . | awk 'NR==2{print $4}')
  avail_gb=$((avail_kb / 1024 / 1024))
  if [[ "$avail_gb" -ge 15 ]]; then pass "Disk free ~${avail_gb} GB (images ~4GB+)"; else warn_ "Disk free ~${avail_gb} GB — may be tight for images/build"; fi
fi

if free -g >/dev/null 2>&1; then
  mem=$(free -g | awk '/Mem:/{print $2}')
  if [[ "${mem:-0}" -ge 8 ]]; then pass "RAM ~${mem} GB"; else warn_ "RAM ~${mem} GB — official compose limits are heavy; use lab mem_limit or bigger host"; fi
fi

probe() {
  local name="$1" url="$2"
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 12 -L "$url" 2>/dev/null || true)
  [[ "$code" =~ ^[0-9]{3}$ ]] || code="000"
  if [[ "$code" =~ ^(200|301|302|401|403|404)$ ]]; then pass "Reachable: $name (HTTP $code)"; else warn_ "Unreachable/slow: $name ($url → HTTP $code)"; fi
}

say ""
say "--- network (best-effort) ---"
probe "GitHub firecrawl" "https://github.com/firecrawl/firecrawl"
probe "docs self-host" "https://docs.firecrawl.dev/contributing/self-host"
probe "GHCR firecrawl packages" "https://github.com/orgs/firecrawl/packages"
probe "Docker Hub redis alpine" "https://hub.docker.com/v2/repositories/library/redis/tags/alpine"
probe "example.com" "https://example.com"

say ""
say "=== summary: ${ok} ok / ${warn} warn / ${bad} bad ==="
[[ "$bad" -gt 0 ]] && exit 1
exit 0
