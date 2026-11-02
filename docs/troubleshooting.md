# 常见报错（Firecrawl 自托管）

对照上游：[`SELF_HOST.md`](https://github.com/firecrawl/firecrawl/blob/main/SELF_HOST.md) 与 [Self-hosting docs](https://docs.firecrawl.dev/contributing/self-host)。

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| `You're bypassing authentication` | `USE_DB_AUTHENTICATION=false` | 本地 lab 预期警告；公网暴露前不要忽略 |
| Playwright 容器立刻退出，日志含 `registry.npmjs.org` / corepack | 默认 `pnpm start` 触发 corepack 下载 | 用本仓 compose 的 `command: ["node","dist/api.js"]` |
| `getaddrinfo EAI_AGAIN nuq-postgres` / Redis | Compose 网络 DNS / 桥接异常；服务未就绪 | `docker compose ps`；等 postgres healthy；检查 Docker iptables；重试 `up` |
| `/v0/health/readiness` 200 但 `/v2/scrape` 超时 | readiness **不**覆盖 Redis/Playwright/出网 | 查 `api` + `playwright-service` logs；测容器出网与互访 |
| Redis `Connection refused` / 指到 `localhost` | `.env` 里 Redis URL 写成宿主机地址 | Compose 内必须是 `redis://redis:6379` |
| Postgres 起不来 | 密码特殊字符、`POSTGRES_DB` 非 `postgres`（钉版本文档要求） | 按官方 quickstart 保持 `POSTGRES_DB=postgres`；密码加引号 |
| 内存杀进程 / OOM | 官方 compose 默认 API 8G + Playwright 4G 量级 | 降并发 env，或换更大机器；本仓 lab 文件已降 `mem_limit` |
| 构建极慢 | `--build` 拉依赖 | 改走 GHCR 镜像路径；或给 Docker/Git 配代理 |
| SDK 要 API Key | 自托管默认可不带 Key（云端才强制） | 见上游 troubleshooting「API Keys for SDK Usage」 |

自检顺序：

```bash
./scripts/preflight.sh
docker compose -f compose/docker-compose.images.yml --env-file compose/.env ps -a
docker compose -f compose/docker-compose.images.yml --env-file compose/.env logs --tail=100 api playwright-service
./scripts/smoke.sh
```
