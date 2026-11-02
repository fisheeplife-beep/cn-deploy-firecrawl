#!/usr/bin/env bash
# Readiness + /v2/scrape smoke against local Firecrawl.
set -euo pipefail
BASE="${FIRECRAWL_BASE:-http://127.0.0.1:3002}"
say() { printf '%s\n' "$*"; }

say "=== readiness $BASE/v0/health/readiness ==="
ready=0
for i in $(seq 1 60); do
  if body=$(curl -fsS --max-time 5 "$BASE/v0/health/readiness" 2>/dev/null); then
    say "try $i: $body"
    if echo "$body" | grep -q ok; then ready=1; break; fi
  else
    say "try $i: not ready"
  fi
  sleep 3
done
[[ "$ready" == "1" ]] || { say "FAIL readiness"; exit 1; }

say "=== scrape example.com ==="
tmp=$(mktemp)
code=$(curl -sS -o "$tmp" -w '%{http_code}' --max-time 90 \
  -X POST "$BASE/v2/scrape" \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com","formats":["markdown"],"timeout":60000}' || true)
say "HTTP $code"
if [[ "$code" != "200" ]]; then
  head -c 2000 "$tmp" || true
  say "FAIL scrape HTTP"
  exit 1
fi
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d.get("success") is True, d; md=(d.get("data") or {}).get("markdown") or ""; assert len(md)>20; print("OK scrape markdown_len=", len(md)); print(md[:160].replace("\n"," "))' "$tmp"
say "SMOKE_OK"
