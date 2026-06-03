# Mihomo NAS Proxy

> 一行命令，让 NAS 变成家庭级代理网关。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](docker-compose.yml)
[![Mihomo](https://img.shields.io/badge/Mihomo-Alpha-green)](https://github.com/MetaCubeX/mihomo)
[![MetaCubeXD](https://img.shields.io/badge/UI-MetaCubeXD-purple)](https://github.com/MetaCubeX/metacubexd)
[![CI](https://github.com/Lgugeng/mihomo-nas-proxy/actions/workflows/ci.yml/badge.svg)](https://github.com/Lgugeng/mihomo-nas-proxy/actions/workflows/ci.yml)

---

## 这是什么

基于 [Mihomo](https://github.com/MetaCubeX/mihomo)（Clash Meta 内核）+ [MetaCubeXD](https://github.com/MetaCubeX/metacubexd) Web 管理界面，用 Docker 部署在 NAS 上，让家里所有设备共享一个代理节点。

**适用场景：**
- 家里多台设备（电脑、手机、平板、电视）需要代理
- 不想每台设备单独装客户端
- 有一个 NAS 或闲置 Linux 机器
- 想通过 Web UI 统一管理节点和规则

**支持架构：** `amd64` / `arm64` / `armv7`（树莓派、群晖、飞牛、Unraid 等）

## 架构

```
┌─────────────────────────────────────────────────────┐
│                        NAS                           │
│                                                      │
│  ┌──────────────────┐   ┌──────────────────┐        │
│  │   MetaCubeXD     │   │    Grafana       │ 可选   │
│  │   :9090/ui       │   │    :3000         │        │
│  └────────┬─────────┘   └────────┬─────────┘        │
│           │                      │                   │
│  ┌────────▼─────────┐   ┌────────▼─────────┐        │
│  │     Mihomo       │   │   Prometheus     │ 可选   │
│  │   :9090 API      │   │   :9091          │        │
│  └────────┬─────────┘   └──────────────────┘        │
│     ┌─────┴──────┐                                   │
│     ▼            ▼                                   │
│  :7890        :7891                                  │
│  HTTP         SOCKS5                                 │
└─────┬────────────┬───────────────────────────────────┘
      │            │
      ▼            ▼
  ┌────────┐  ┌────────┐  ┌────────┐
  │ 电脑   │  │  手机  │  │ 电视   │
  └────────┘  └────────┘  └────────┘
```

## 快速开始

```bash
# 1. 克隆项目
git clone https://github.com/Lgugeng/mihomo-nas-proxy.git
cd mihomo-nas-proxy

# 2. 配置
cp .env.example .env
# 编辑 .env，填入你的订阅链接

# 3. 一键部署
make setup
```

部署完成后：

| 服务 | 地址 |
|------|------|
| Web 管理界面 | `http://NAS_IP:9090/ui/` |
| HTTP 代理 | `NAS_IP:7890` |
| SOCKS5 代理 | `NAS_IP:7891` |

## 常用命令

```bash
make help           # 查看所有命令
make up             # 启动服务
make down           # 停止服务
make restart        # 重启服务
make logs           # 查看日志
make status         # 查看状态
make update         # 更新镜像
make test           # 测试连通性
make backup         # 备份配置
make clean          # 清理所有数据
make monitor        # 执行一次健康检查
make monitor-on     # 启用定时监控（每小时）
make monitor-off    # 禁用定时监控
make auto-update    # 检查并自动更新镜像
make monitor-up     # 启动监控面板
make monitor-down   # 停止监控面板
```

## 功能特性

### 多订阅源支持

支持同时使用两个订阅源，节点自动合并：

```env
# .env
CLASH_SUBSCRIPTION_URL=https://机场1的订阅链接
CLASH_SUBSCRIPTION_URL_2=https://机场2的订阅链接
```

### TUN 模式（全局透明代理）

启用后所有设备自动走代理，无需单独配置：

```env
# .env
ENABLE_TUN=true
```

适用场景：智能电视、游戏主机、IoT 设备。详见 [TUN 模式指南](docs/tun-mode.md)。

### 健康监控

定时检查订阅有效性和节点状态，支持告警推送：

```env
# .env（二选一）
BARK_URL=https://api.day.app/YOUR_KEY          # iOS Bark 推送
TELEGRAM_URL=https://api.telegram.org/bot...   # Telegram 推送
```

```bash
make monitor      # 手动执行一次检查
make monitor-on   # 启用每小时自动检查
make monitor-off  # 禁用自动检查
```

### 监控面板（Prometheus + Grafana）

可视化监控代理流量、连接数、节点延迟：

```env
# .env
ENABLE_MONITORING=true
GRAFANA_ADMIN_PASSWORD=your_password
```

```bash
make monitor-up   # 启动监控面板
# 访问 http://NAS_IP:3000 查看 Grafana
```

详见 [监控面板指南](docs/monitoring.md)。

### 自动更新

检查新镜像并自动更新，支持推送通知：

```bash
make auto-update  # 执行一次检查
```

配合 cron 可实现定时自动更新。

## 目录结构

```
mihomo-nas-proxy/
├── docker-compose.yml          # Docker 编排
├── Makefile                    # 常用命令封装
├── config/
│   ├── config.yaml.template    # 配置模板（安全，无敏感信息）
│   ├── prometheus.yml          # Prometheus 抓取配置
│   └── grafana/                # Grafana 自动配置
│       ├── provisioning/       # 数据源和仪表盘自动加载
│       └── dashboards/         # 预置仪表盘
├── mihomo/                     # 运行时数据（gitignored）
│   ├── config.yaml             # 实际配置（从模板生成）
│   ├── providers/              # 订阅数据
│   └── ui/                     # MetaCubeXD 前端
├── scripts/
│   ├── setup.sh                # 一键部署脚本
│   ├── health-check.sh         # 健康监控脚本
│   └── auto-update.sh          # 自动更新脚本
├── docs/
│   ├── deploy.md               # 详细部署文档
│   ├── troubleshoot.md         # 故障排查指南
│   ├── tun-mode.md             # TUN 模式指南
│   └── monitoring.md           # 监控面板指南
├── .github/workflows/ci.yml   # GitHub Actions CI
├── .env.example                # 环境变量示例
├── .gitignore
├── .yamllint.yml               # YAML 语法检查配置
├── CONTRIBUTING.md             # 贡献指南
├── CHANGELOG.md                # 版本记录
└── SECURITY.md                 # 安全策略
```

## 设备配置

### Windows

设置 → 网络和 Internet → 代理 → 手动代理：
- 地址：`NAS_IP`，端口：`7890`

或使用 [Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev) 客户端。

### macOS

系统设置 → 网络 → Wi-Fi → 代理：
- HTTP 代理：`NAS_IP:7890`
- SOCKS 代理：`NAS_IP:7891`

### 手机

WiFi 设置 → 手动代理：
- 服务器：`NAS_IP`，端口：`7890`

### Docker 容器

```bash
docker run -e HTTP_PROXY=http://NAS_IP:7890 -e HTTPS_PROXY=http://NAS_IP:7890 ...
```

### Linux 系统

```bash
export http_proxy=http://NAS_IP:7890
export https_proxy=http://NAS_IP:7890
```

### 智能电视 / 游戏主机

启用 TUN 模式即可，无需在设备上配置。详见 [TUN 模式指南](docs/tun-mode.md)。

## 配置说明

### 代理分组

| 分组 | 用途 | 说明 |
|------|------|------|
| PROXY | 主选择 | 手动选择节点，或选择下面的子分组 |
| AUTO | 自动选择 | 自动测速，选择延迟最低的节点 |
| AI 服务 | AI 专用 | ChatGPT / Claude 等，过滤美国/日本/新加坡节点 |
| 流媒体 | 流媒体专用 | Netflix / YouTube 等，过滤港台日美节点 |
| 电报 | Telegram 专用 | 过滤新加坡/日本/韩国/德国节点 |

### 规则说明

- 私有地址（局域网）→ 直连
- AI 服务域名 → AI 服务分组
- 流媒体域名 → 流媒体分组
- Telegram → 电报分组
- GitHub / 游戏平台 → 代理
- 国内常用域名 → 直连
- 中国 IP → 直连
- 其他流量 → PROXY 分组

## 硬件兼容

| 设备 | 架构 | 支持状态 |
|------|------|----------|
| x86 NAS / 服务器 | amd64 | ✅ 完全支持 |
| ARM NAS（群晖、飞牛） | arm64 | ✅ 完全支持 |
| 树莓派 4/5 | arm64 | ✅ 完全支持 |
| 树莓派 3 | armv7 | ✅ 支持 |

## 安全建议

1. **修改默认密码**：部署后立即在 Web UI 中修改 `secret`
2. **限制访问**：默认仅本机可访问 API，如需局域网访问请自行修改配置
3. **定期更新**：运行 `make update` 更新到最新版本
4. **备份配置**：运行 `make backup` 备份配置文件

## 参考

- [Mihomo 官方文档](https://wiki.metacubex.one/)
- [MetaCubeXD](https://github.com/MetaCubeX/metacubexd)
- [Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev)

## 贡献

欢迎提交 Issue 和 Pull Request！请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

## License

[MIT](LICENSE)
