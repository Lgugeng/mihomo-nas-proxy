# 迭代计划 — Mihomo NAS Proxy

## 一、项目审查报告（问题清单）

### 🔴 P0 — 必须修复（阻塞发布）

| # | 类型 | 问题 | 位置 | 影响 |
|---|------|------|------|------|
| 1 | 安全 | `.gitignore` 漏掉了 `mihomo/config.yaml`，真实配置（含订阅链接和密码）会被提交到 Git | `.gitignore` | 订阅泄露 |
| 2 | 安全 | `healthcheck` 使用 `wget http://127.0.0.1:9090`，等于把未鉴权的 API 暴露给健康检查 | `docker-compose.yml` | 信息泄露 |
| 3 | 结构 | `mihomo/config.yaml` 已存在于仓库中，含占位符 `CLASH_SUBSCRIPTION_URL`，但 `.gitignore` 忽略的是 `config/config.yaml` 而非 `mihomo/config.yaml` | `.gitignore` | 配置混乱 |
| 4 | 结构 | 根目录残留 `mihomo.zip`（6.5MB），不应进入 Git | 根目录 | 仓库臃肿 |
| 5 | 命名 | 项目名 `clash-proxy` 与实际技术栈 `Mihomo` 不一致，README 标题是 `Mihomo NAS Proxy` | 全局 | 用户困惑 |
| 6 | 脚本 | `setup.sh` 不加载 `.env` 文件，用户设置了 `.env` 但脚本读不到 | `scripts/setup.sh` | 部署失败 |

### 🟠 P1 — 应该修复（影响体验）

| # | 类型 | 问题 | 位置 | 影响 |
|---|------|------|------|------|
| 7 | 兼容 | `version: "3.8"` 在 Docker Compose V2 中已废弃，会报警告 | `docker-compose.yml` | 日志噪音 |
| 8 | 安全 | `network_mode: host` + `pid: host` + `ipc: host` 权限过大，`pid` 和 `ipc` 对代理服务无用 | `docker-compose.yml` | 攻击面过大 |
| 9 | 配置 | DNS `listen: 0.0.0.0:1053` 在 host 网络下会占用系统 1053 端口，可能与其他服务冲突 | `config.yaml.template` | 端口冲突 |
| 10 | 配置 | `external-controller: 0.0.0.0:9090` 暴露 API 到整个局域网，无鉴权保护 | `config.yaml.template` | 未授权访问 |
| 11 | 脚本 | `setup.sh` 用 `sed` 替换配置，macOS `sed` 和 GNU `sed` 语法不同，macOS 用户会报错 | `scripts/setup.sh` | macOS 不兼容 |
| 12 | 文档 | README 缺少项目一句话介绍、适用场景、架构图太简陋 | `README.md` | 第一印象差 |
| 13 | 文档 | `docs/` 下有 4 个文档，内容重叠，`deploy-original.md` 和 `device-config.md` 是原始笔记不应进仓库 | `docs/` | 文档混乱 |
| 14 | 结构 | 缺少 `CONTRIBUTING.md`、`CHANGELOG.md`，开源项目必备 | 根目录 | 不专业 |

### 🟡 P2 — 建议优化（提升质量）

| # | 类型 | 问题 | 位置 | 影响 |
|---|------|------|------|------|
| 15 | 配置 | `proxy-groups` 的 `filter` 依赖节点名包含中文，如果机场节点名改了就失效 | `config.yaml.template` | 分组失效 |
| 16 | 配置 | 规则太少，缺少 Telegram、GitHub、Steam 等常用代理规则 | `config.yaml.template` | 体验差 |
| 17 | 脚本 | 缺少 `Makefile` 封装常用操作（启动/停止/更新/日志） | 根目录 | 操作不便 |
| 18 | CI | 缺少 GitHub Actions 做 YAML 语法检查和 ShellCheck | `.github/` | 代码质量 |
| 19 | 文档 | 缺少架构设计文档，说清楚为什么选 Mihomo、为什么用 host 网络 | `docs/` | 技术决策不明 |
| 20 | 安全 | 缺少安全策略文件 `SECURITY.md` | 根目录 | 安全响应无流程 |

---

## 二、迭代版本规划

### v1.0.0 — 安全基线（本次发布）

> 目标：消除所有安全和结构问题，达到可公开发布的状态。

**任务清单：**

| 任务 | 负责 | 优先级 | 预估 |
|------|------|--------|------|
| T1: 修复 `.gitignore`，忽略 `mihomo/config.yaml` 和 `mihomo.zip` | 工程 | P0 | 5min |
| T2: 删除根目录 `mihomo.zip` 和 `mihomo/config.yaml` | 工程 | P0 | 2min |
| T3: 清理 `docs/` 目录，删除原始笔记 | 工程 | P0 | 3min |
| T4: 重命名项目为 `mihomo-nas-proxy`，统一命名 | 产品 | P0 | 10min |
| T5: 修复 `setup.sh` 支持加载 `.env` 文件 | 工程 | P0 | 15min |
| T6: 修复 `docker-compose.yml`（去 version、收紧权限、修复 healthcheck） | 工程 | P0 | 10min |
| T7: 修复 `config.yaml.template`（收紧 external-controller、DNS listen） | 工程 | P0 | 10min |
| T8: 重写 `README.md`（加 badges、场景说明、清晰架构图） | 产品 | P1 | 20min |
| T9: 新增 `CONTRIBUTING.md` | 产品 | P1 | 10min |
| T10: 新增 `CHANGELOG.md` | 产品 | P1 | 5min |
| T11: 新增 `Makefile` 封装常用命令 | 工程 | P1 | 10min |
| T12: `setup.sh` 兼容 macOS（用 `awk` 替代 `sed`） | 工程 | P1 | 10min |
| T13: 丰富规则集（Telegram/GitHub/Steam 等） | 工程 | P2 | 15min |
| T14: 新增 `.github/workflows/lint.yml`（YAML + ShellCheck） | 工程 | P2 | 15min |
| T15: 新增 `SECURITY.md` | 产品 | P2 | 5min |
| T16: Git 初始化 + 首次提交 | 工程 | P0 | 5min |

### v1.1.0 — 体验增强（下次迭代）

- TUN 模式配置模板
- 路由器级全屋代理方案
- 订阅健康监控脚本
- 多订阅源支持
- Grafana + Prometheus 监控面板

### v1.2.0 — 生态完善

- GitHub Actions 自动化发布
- 支持 ARM 架构（树莓派）
- 一键更新脚本
- 配置文件版本管理

---

## 三、分工计划

### 产品经理负责

1. 项目命名和定位
2. README 产品化（让用户 30 秒看懂项目）
3. CONTRIBUTING.md（贡献指南）
4. CHANGELOG.md（版本记录）
5. SECURITY.md（安全策略）
6. 文档结构规划

### 全栈工程师负责

1. `.gitignore` 修复
2. `docker-compose.yml` 优化
3. `config.yaml.template` 安全加固
4. `setup.sh` 兼容性修复 + `.env` 加载
5. `Makefile` 编写
6. GitHub Actions CI 配置
7. 规则集丰富
8. Git 初始化和首次提交
