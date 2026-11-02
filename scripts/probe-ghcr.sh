#!/usr/bin/env bash
# Probe public GHCR OCI indexes for Firecrawl images (no Docker required).
set -euo pipefail
OUT="${1:-}"
python3 - "$OUT" <<'PY'
import json, os, sys, urllib.request, datetime

out_path = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else None
lines = [f"# GHCR probe {datetime.datetime.now().astimezone().strftime('%Y-%m-%d %H:%M:%S %z')}"]

def token(repo):
    url = f"https://ghcr.io/token?service=ghcr.io&scope=repository:{repo}:pull"
    with urllib.request.urlopen(url, timeout=30) as r:
        return json.load(r)["token"]

def probe(repo, tag):
    tok = token(repo)
    req = urllib.request.Request(
        f"https://ghcr.io/v2/{repo}/manifests/{tag}",
        headers={
            "Authorization": f"Bearer {tok}",
            "Accept": "application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            body = r.read()
            code = r.status
    except Exception as e:
        lines.append(f"FAIL ghcr.io/{repo}:{tag} {e}")
        return False
    idx = json.loads(body)
    plats = []
    for m in idx.get("manifests") or []:
        p = m.get("platform") or {}
        if p.get("os") and p.get("os") != "unknown":
            plats.append(f"{p.get('os')}/{p.get('architecture')}")
    lines.append(
        f"OK ghcr.io/{repo}:{tag} mediaType={idx.get('mediaType','?')} plats={','.join(plats) or 'n/a'}"
    )
    return True

ok = True
ok &= probe("firecrawl/firecrawl", "latest")
probe("firecrawl/firecrawl", "2.11.162")
ok &= probe("firecrawl/playwright-service", "latest")
ok &= probe("firecrawl/nuq-postgres", "latest")
text = "\n".join(lines) + "\n"
sys.stderr.write(text)
if out_path:
    open(out_path, "w").write(text)
sys.exit(0 if ok else 1)
PY
