# 更新日志

本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [1.2.0] - 2026-06-03

### 新增
- **监控面板**：Prometheus + Grafana 可视化监控（连接数/流量/节点延迟）
- **自动更新**：检查新镜像并自动更新，支持 Bark/Telegram 推送通知
- **GitHub Actions CI**：YAML 语法检查 + ShellCheck + Docker Compose 验证
- 预置 Grafana 仪表盘 `config/grafana/dashboards/mihomo.json`
- Prometheus 配置 `config/prometheus.yml`
- 自动更新脚本 `scripts/auto-update.sh`
- 监控面板文档 `docs/monitoring.md`
- Makefile 新增 `monitor-up` / `monitor-down` / `monitor-logs` / `auto-update` 命令
- README 新增硬件兼容性说明（amd64/arm64/armv7）

### 变更
- `docker-compose.yml` 新增 Prometheus 和 Grafana 服务（通过 profile 按需启用）
- `.env.example` 新增 `ENABLE_MONITORING`、`GRAFANA_ADMIN_PASSWORD`
- `setup.sh` 支持 `ENABLE_MONITORING` 环境变量

## [1.1.0] - 2026-06-03

### 新增
- **TUN 模式**：全局透明代理，智能电视/游戏主机等无需配置即可走代理
- **多订阅源**：支持同时使用两个订阅源，节点自动合并
- **健康监控**：定时检查订阅有效性和节点状态，支持 Bark/Telegram 告警推送
- TUN 模式详细文档 `docs/tun-mode.md`
- 健康监控脚本 `scripts/health-check.sh`
- Makefile 新增 `monitor` / `monitor-on` / `monitor-off` 命令

### 变更
- `.env.example` 新增 `CLASH_SUBSCRIPTION_URL_2`、`ENABLE_TUN`、`BARK_URL`、`TELEGRAM_URL`
- `config.yaml.template` 新增 TUN 配置段和第二订阅源支持
- `setup.sh` 支持多源替换和 TUN 开关
- `README.md` 更新功能说明

## [1.0.0] - 2026-06-03

### 新增
- 基于 Mihomo + MetaCubeXD 的 Docker 部署方案
- 一键部署脚本 `scripts/setup.sh`
- 配置模板 `config/config.yaml.template`
- DNS 优化配置（fake-ip 模式 + 国内外分流）
- 分应用代理组（AI 服务 / 流媒体）
- 代理规则集（AI / 流媒体 / Telegram / GitHub）
- Docker 健康检查
- 日志轮转配置
- Makefile 命令封装
- 完整文档体系（部署 / 故障排查 / 贡献指南）

### 安全
- 敏感信息通过环境变量管理
- API 默认仅本机访问
- 容器权限收紧（NET_ADMIN + NET_RAW）
