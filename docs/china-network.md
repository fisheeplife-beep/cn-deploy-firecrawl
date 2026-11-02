# 国内网络说明（Firecrawl）

## 你需要通的几条链路

| 用途 | 地址 | 国内常见情况 |
|------|------|----------------|
| 源码 / tag | `github.com/firecrawl/firecrawl` | clone 常慢；可用代理或 `ghproxy` 类镜像（自担风险） |
| 官方文档 | `docs.firecrawl.dev` | 多数时候可访问；有[中文自托管页](https://docs.firecrawl.dev/zh/contributing/self-host) |
| API / Playwright / Postgres 镜像 | `ghcr.io/firecrawl/*` | GHCR 偶发慢或需登录策略；本仓 `probe-ghcr.sh` 可先测 |
| Redis / RabbitMQ | `docker.io/library/redis`、`rabbitmq` | Docker Hub 常需镜像加速或代理 |
| Playwright 默认启动 | `registry.npmjs.org`（corepack 拉 pnpm） | **易卡**；本仓 compose 用 `node dist/api.js` 绕过 |
| 抓取目标站 | 任意外网 URL | 出网/代理由你的 VPS 决定；可设 `PROXY_*` |
| npm / AI Provider（可选） | OpenAI 兼容端点、Ollama 等 | 仅在启用 extract / LLM 格式时需要 |

## 推荐策略

1. **有 Docker、想少编译**：用本仓 `compose/docker-compose.images.yml` 拉 GHCR + Hub 预构建镜像（见主 README「路径 A」）。
2. **要跟官方文档钉版本**：`git clone` + `git checkout v2.11.162` + 根目录 `.env` + `docker compose up --build`（路径 B）。国内第一次 build 会拉大量 Node/系统依赖，务必代理。
3. **Docker Hub / GHCR 慢**：配置 daemon 镜像加速，或 `HTTPS_PROXY` 后再 `docker pull`；也可在能访问的环境 pull 后 `docker save | docker load`。
4. **Playwright 容器反复因 pnpm/corepack 挂掉**：确认使用本仓 compose 的 `command: ["node", "dist/api.js"]`，或在自改 compose 里同样覆盖入口。

## 安全（务必读）

- 官方 quickstart 的 `USE_DB_AUTHENTICATION=false` **只适合可信内网**。不要把 `0.0.0.0:3002` 裸奔到公网。
- 本仓 image compose 默认只绑定 **`127.0.0.1:3002`**。若改成对外暴露，先上反代 TLS、网络 ACL，并按上游「Before production」补齐身份与持久化。
- 不要提交 `.env`；`POSTGRES_PASSWORD` / `BULL_AUTH_KEY` / `OPENAI_API_KEY` 用密钥管理。
