# Firecrawl 国内可跟做部署配套

> 上游仓库：[firecrawl/firecrawl](https://github.com/firecrawl/firecrawl)（**AGPL-3.0**）  
> 官方自托管文档：https://docs.firecrawl.dev/contributing/self-host （[中文](https://docs.firecrawl.dev/zh/contributing/self-host)）  
> 上游说明：仓库内 [`SELF_HOST.md`](https://github.com/firecrawl/firecrawl/blob/main/SELF_HOST.md) · 根目录 `docker-compose.yaml`  
> 本仓性质：**独立中文部署配套**（预检 / GHCR 探针 / 镜像版 Compose / 国内网络与踩坑），**不是**官方镜像或 fork，也**不会**整页搬运上游 README。

Firecrawl 把网页抓成 **Markdown / 结构化数据**，方便喂给 Agent。自托管用 Docker Compose 拉起 API + Playwright + Redis + RabbitMQ + Postgres（NuQ 队列）。  
本仓目标：在**国内网络 / 常见 Linux VPS**上，按一条最短路径跟做到「能 scrape」，并事先知道作者验证到哪一步。

系列索引：[cn-deploy](https://github.com/fisheeplife-beep/cn-deploy)

---

## 验证边界（请先看）

| 路径 | 本仓作者环境验证状态（2026-11-02，Asia/Shanghai，Linux x86_64） |
|------|--------------------------------------------------------------|
| **上游身份 / 文档钉版本** | ✅ **已确认** — 官方 self-host 文档钉 **`v2.11.162`**；本机浅克隆该 tag 成功；上游 AGPL-3.0 |
| **GHCR OCI 索引** | ✅ **已验证（HTTP，无需 Docker）** — `ghcr.io/firecrawl/firecrawl:latest` 与 `:2.11.162`、`playwright-service:latest`、`nuq-postgres:latest` 均为 **200**，含 **linux/amd64 + linux/arm64**。见 [`examples/ghcr-probe.txt`](./examples/ghcr-probe.txt) |
| **`docker pull` 上述镜像 + Hub `redis:alpine` / `rabbitmq:3-management`** | ✅ **已验证** — 见 [`examples/docker-bootstrap.txt`](./examples/docker-bootstrap.txt) |
| **镜像 Compose 起栈** | ✅ **部分验证** — 五容器可创建并启动；Playwright 日志 `Server is running on port 3000`；API 曾返回 `/v0/health/readiness` → `{"status":"ok"}` |
| **端到端 `POST /v2/scrape`（example.com → markdown）** | ⚠️ **未跑通** — 作者沙箱 Docker **桥接网络容器间 TCP 超时**（api→redis / playwright `TIMEOUT`），scrape 请求无响应体。属**环境网络限制**，不是断言上游坏了。请你在正常 Docker 主机复测 |
| **官方路径：`checkout v2.11.162` + `docker compose up --build`** | ⚠️ **未在本机验证**（未完整源码构建） |
| **生产：鉴权 / TLS / 持久卷 / Fire-engine / Cloud 专属能力** | ⚠️ **未验证**（明确超出本仓 lab 范围） |

示例与探针输出：[`examples/`](./examples/)。

---

## 选哪条路？

| 场景 | 推荐 |
|------|------|
| **国内 VPS，想少编译、先跑通 scrape** | **路径 A：本仓镜像 Compose**（GHCR 预构建 + Hub Redis/RabbitMQ） |
| **严格跟官方文档钉 git tag** | **路径 B：`v2.11.162` + `docker compose up --build`** |
| 只想确认镜像能不能解析 | `./scripts/probe-ghcr.sh` |
| Kubernetes / Helm | 见上游 `examples/kubernetes/`（本仓未覆盖） |

**主推：路径 A**（步骤短、适合国内拉镜像；版本上 API 用 GHCR `latest` 与 sidecar 对齐，或自行钉 `FIRECRAWL_IMAGE_TAG=2.11.162` 并接受 playwright/nuq 仍多为 `latest` 的现状）。

---

## 环境要求

| 项 | 建议 |
|----|------|
| OS | 常见 Linux（Ubuntu 等）；macOS Docker Desktop 亦可 |
| 资源 | 官方未给硬下限；Compose 默认限额约 **API 8G + Playwright 4G** 量级。本仓 lab 文件降到约 **2.5G + 1.5G**，**≥8GB RAM** 更稳 |
| 软件 | Docker Engine + **Compose v2**（`docker compose`）+ `curl` + `git` |
| 端口 | 本仓默认 **`127.0.0.1:3002`** |
| 出网 | 拉镜像要通 GHCR / Docker Hub；scrape 要通目标站 |

可选先体检：

```bash
git clone https://github.com/fisheeplife-beep/cn-deploy-firecrawl.git
cd cn-deploy-firecrawl
./scripts/preflight.sh
./scripts/probe-ghcr.sh
# 若已装 cn-deploy-doctor，可再跑一遍磁盘/代理体检
```

---

## 路径 A｜镜像 Compose（本仓主推）

### 1. 配置环境变量

```bash
cp .env.example compose/.env
# 编辑 compose/.env：把 POSTGRES_PASSWORD 换成 ≥32 位随机串
```

### 2. 启动

```bash
./scripts/up-images.sh
# 等价：
# docker compose -f compose/docker-compose.images.yml --env-file compose/.env up -d
```

说明：

- 使用 `ghcr.io/firecrawl/firecrawl`、`playwright-service`、`nuq-postgres` + 官方 Hub 的 Redis / RabbitMQ。
- Playwright 覆盖为 `node dist/api.js`，避免启动时 corepack 去拉 `registry.npmjs.org`。
- API **只监听 127.0.0.1**，降低误暴露风险。

### 3. 冒烟

```bash
./scripts/smoke.sh
```

手动等价：

```bash
curl -fsS http://127.0.0.1:3002/v0/health/readiness
# 期望：{"status":"ok"}

curl -fsS --max-time 90 -X POST http://127.0.0.1:3002/v2/scrape \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com","formats":["markdown"],"timeout":60000}'
# 期望：success=true，且 data.markdown 非空
```

> readiness **只是心跳**，不能代替 scrape。

---

## 路径 B｜官方钉版本源码构建

按官方文档（验证基线 `v2.11.162`）：

```bash
./scripts/clone-upstream.sh   # 默认 tag=v2.11.162 → data/upstream-firecrawl
cd data/upstream-firecrawl

# 在上游根目录创建 .env（勿提交）：
# USE_DB_AUTHENTICATION=false
# POSTGRES_USER=postgres
# POSTGRES_PASSWORD=<至少32位随机串>
# POSTGRES_DB=postgres

docker compose up --build -d
docker compose ps --all
```

冒烟命令与路径 A 相同（默认 `http://localhost:3002`；注意官方 compose 常映射 `3002:3002`，**生产勿裸奔**）。

国内 clone/build 慢：见 [`docs/china-network.md`](./docs/china-network.md)。

---

## 安全注意（勿裸奔）

1. `USE_DB_AUTHENTICATION=false` 时**没有可用的 API Key 门禁**——只适合本机 / 受信内网。  
2. 不要把未鉴权的 3002 端口直接挂到公网 IP；需要对外时用反代 + TLS + 网络 ACL，并阅读官方 **Before production**。  
3. Postgres 默认不映射到宿主机；不要随手加 `ports:`。  
4. 若启用队列管理界面，设置强 `BULL_AUTH_KEY`。  
5. `.env` 永不进 Git。

---

## 国内网络 / 常见报错

- [`docs/china-network.md`](./docs/china-network.md)  
- [`docs/troubleshooting.md`](./docs/troubleshooting.md)

---

## 开源边界与上游差异

- 上游功能以开源 Compose 为准：**Fire-engine、部分截图/动作、部分 Cloud Agent 能力不在默认自托管栈**。详见官方「Self-hosted feature support」。  
- 本仓不重新分发上游镜像层；仅提供编排与文档。升级请跟上游 tag / GHCR digest。  
- 本配套 MIT；使用 Firecrawl 源码或镜像请遵守 **AGPL-3.0**。

---

## 系列

- 索引：[cn-deploy](https://github.com/fisheeplife-beep/cn-deploy)  
- 体检：[cn-deploy-doctor](https://github.com/fisheeplife-beep/cn-deploy-doctor)  
- 选题：[trending-gap-radar](https://github.com/fisheeplife-beep/trending-gap-radar)
