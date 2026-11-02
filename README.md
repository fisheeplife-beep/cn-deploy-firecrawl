# cn-deploy-firecrawl

Chinese, follow-along **deployment companion** for [firecrawl/firecrawl](https://github.com/firecrawl/firecrawl) — not an official fork, and not a verbatim copy of upstream docs.

**Start here (ZH):** [README.zh-CN.md](./README.zh-CN.md)

### What you get

- Preflight + GHCR probe scripts (no Docker required for probe)
- Image-based Compose lab file (`compose/docker-compose.images.yml`) with `127.0.0.1` bind and Playwright `node dist/api.js` override (avoids corepack→npm at boot)
- China network notes + troubleshooting
- Honest verification boundary from the author box

### Verification snapshot (author box, 2026-11-02, Asia/Shanghai, Linux x86_64)

| Path | Status |
|------|--------|
| GHCR OCI indexes (`firecrawl:latest` / `2.11.162`, `playwright-service:latest`, `nuq-postgres:latest`) | **Verified** (HTTP 200, linux/amd64+arm64) |
| `docker pull` of those images + `redis:alpine` + `rabbitmq:3-management` | **Verified** |
| Compose up → all 5 containers start; Playwright listens; `/v0/health/readiness` → `{"status":"ok"}` | **Verified** (once) |
| End-to-end `POST /v2/scrape` → Markdown | **Not verified** — Docker bridge inter-container TCP timed out in this sandbox |
| Official `git checkout v2.11.162` + `docker compose up --build` | **Not verified** (build not run here) |
| Production auth / TLS / durable volumes / Fire-engine / Cloud-only features | **Not verified** (out of scope) |

### Quick start (image path)

```bash
cp .env.example compose/.env   # set a strong POSTGRES_PASSWORD
./scripts/preflight.sh
./scripts/probe-ghcr.sh
./scripts/up-images.sh
./scripts/smoke.sh             # readiness + scrape
```

Upstream is **AGPL-3.0**. This companion (scripts + notes) is [MIT](./LICENSE).  
Docs: https://docs.firecrawl.dev/contributing/self-host · Series index: https://github.com/fisheeplife-beep/cn-deploy
