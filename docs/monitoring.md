# 监控面板指南

## 概述

本项目支持通过 Prometheus + Grafana 实现代理流量和节点状态的可视化监控。

| 组件 | 端口 | 说明 |
|------|------|------|
| Prometheus | `9091` | 指标采集和存储 |
| Grafana | `3000` | 可视化仪表盘 |
| Mihomo Metrics | `9090/metrics` | 指标暴露端点（自动启用） |

## 快速开始

### 方式一：环境变量

```bash
# 编辑 .env
ENABLE_MONITORING=true
GRAFANA_ADMIN_PASSWORD=your_password  # 默认 mihomo123

# 重新部署
make setup
```

### 方式二：手动启动

```bash
# 启动监控栈
make monitor-up

# 访问 Grafana
# http://NAS_IP:3000
# 用户名：admin
# 密码：mihomo123（或你在 .env 中设置的密码）
```

## 预置仪表盘

Grafana 启动后自动加载「Mihomo 监控面板」，包含以下面板：

| 面板 | 说明 |
|------|------|
| 当前连接数 | 实时活跃连接数 |
| 上传速率 | 当前上传带宽 |
| 下载速率 | 当前下载带宽 |
| 平均延迟 | 所有节点平均延迟 |
| 流量趋势 | 上传/下载速率历史曲线 |
| 连接数趋势 | 活跃连接数历史曲线 |
| 节点延迟 | 各节点延迟对比 |

## 常用命令

```bash
make monitor-up       # 启动监控栈
make monitor-down     # 停止监控栈
make monitor-logs     # 查看监控日志
```

## 自定义仪表盘

1. 登录 Grafana（`http://NAS_IP:3000`）
2. 点击左侧「+」→「New Dashboard」
3. 添加面板，数据源选择「Prometheus」
4. 使用 Mihomo 指标查询：
   - `mihomo_connections` — 当前连接数
   - `rate(mihomo_traffic_up_total[1m])` — 上传速率
   - `rate(mihomo_traffic_down_total[1m])` — 下载速率
   - `mihomo_proxy_delay` — 节点延迟

## 指标说明

Mihomo 暴露的 Prometheus 指标：

| 指标 | 类型 | 说明 |
|------|------|------|
| `mihomo_connections` | Gauge | 当前活跃连接数 |
| `mihomo_traffic_up_total` | Counter | 总上传流量 |
| `mihomo_traffic_down_total` | Counter | 总下载流量 |
| `mihomo_proxy_delay` | Gauge | 各节点延迟（ms） |

## 存储和保留

- Prometheus 数据保留 30 天
- 数据存储在 Docker volume `prometheus-data` 中
- Grafana 数据存储在 Docker volume `grafana-data` 中

### 清理数据

```bash
docker compose --profile monitoring down -v
```

## 故障排查

### Grafana 无法访问

```bash
# 检查容器状态
docker compose --profile monitoring ps

# 查看日志
docker logs mihomo-grafana
```

### Prometheus 无法采集数据

```bash
# 检查 Prometheus targets
# 访问 http://NAS_IP:9091/targets

# 检查 mihomo metrics 端点
curl http://127.0.0.1:9090/metrics
```

### 仪表盘无数据

1. 确认 Prometheus 数据源配置正确
2. 在 Grafana 中点击「Configuration」→「Data Sources」→ 检查连接
3. 在 Explore 中查询 `mihomo_connections` 验证数据
