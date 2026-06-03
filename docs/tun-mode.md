# TUN 模式指南

## 什么是 TUN 模式

TUN 模式是一种全局透明代理方式。与普通代理（HTTP/SOCKS5）不同，TUN 模式在网络层接管所有流量，**无需设备单独配置代理**。

### 对比

| 特性 | HTTP/SOCKS5 代理 | TUN 模式 |
|------|-----------------|----------|
| 配置方式 | 每台设备单独设置代理 | 自动生效，无需配置 |
| 覆盖范围 | 仅支持代理的应用 | 所有应用（包括系统级） |
| 支持协议 | HTTP / SOCKS5 | 所有协议（含 ICMP、UDP） |
| 适用设备 | 电脑、手机 | 所有设备（含智能电视、IoT） |
| DNS 处理 | 应用自行解析 | 统一劫持解析，防 DNS 污染 |

## 适用场景

- **智能电视**：Netflix、YouTube 等应用无法手动设置代理
- **游戏主机**：PlayStation、Xbox、Switch 等
- **IoT 设备**：智能音箱、摄像头等
- **全家翻墙**：不想每台设备都装客户端

## 启用方式

### 方式一：环境变量（推荐）

```bash
# 编辑 .env
ENABLE_TUN=true

# 重新部署
make clean
make setup
```

### 方式二：手动编辑配置

编辑 `mihomo/config.yaml`，取消 `tun:` 段的注释：

```yaml
tun:
  enable: true
  stack: system
  dns-hijack:
    - any:53
  auto-route: true
  auto-detect-interface: true
```

然后重启：

```bash
make restart
```

## 配置说明

| 参数 | 说明 |
|------|------|
| `enable` | 是否启用 TUN |
| `stack` | 网络栈。`system` 性能好，`gvisor` 兼容性好 |
| `dns-hijack` | 劫持 DNS 请求，`any:53` 表示劫持所有 53 端口请求 |
| `auto-route` | 自动添加路由规则 |
| `auto-detect-interface` | 自动检测出口网卡 |

### stack 选择建议

| 选项 | 优点 | 缺点 |
|------|------|------|
| `system` | 性能最好，CPU 占用低 | 需要 root 权限 |
| `gvisor` | 兼容性好，不需要额外权限 | 性能稍差 |
| `mixed` | 自动选择 | 可能不稳定 |

**NAS 推荐**：`system`（Docker 已有 root 权限）

## 注意事项

### 1. 权限要求

TUN 模式需要 `NET_ADMIN` 和 `NET_RAW` 权限，`docker-compose.yml` 已配置。

### 2. 端口冲突

TUN 模式会劫持 DNS（53 端口），如果 NAS 上已有 DNS 服务（如 Pi-hole），需要：
- 关闭原有 DNS 服务，或
- 修改 `dns-hijack` 为特定端口

### 3. 性能影响

TUN 模式会增加少量 CPU 和内存开销，但对 NAS 来说通常可以忽略。

### 4. 与 VPN 冲突

如果 NAS 上同时运行 VPN 服务（如 WireGuard），可能产生路由冲突。建议：
- 使用不同的网段
- 或关闭 VPN 的 DNS 功能

### 5. 容器内 TUN

Docker 容器内使用 TUN 需要宿主机加载 `tun` 模块：

```bash
# 检查是否已加载
lsmod | grep tun

# 如果没有，手动加载
modprobe tun

# 永久加载
echo "tun" >> /etc/modules-load.d/tun.conf
```

## 故障排查

### TUN 模式不生效

```bash
# 检查 TUN 设备
ls -la /dev/net/tun

# 检查容器内是否有 TUN
docker exec mihomo ls -la /dev/net/tun

# 检查日志
docker logs mihomo | grep -i tun
```

### DNS 解析失败

```bash
# 检查 DNS 配置
docker logs mihomo | grep -i dns

# 测试 DNS
nslookup google.com 127.0.0.1 -port=1053
```

### 路由问题

```bash
# 查看路由表
ip route show

# 检查是否有 mihomo 添加的路由
ip route show | grep tun
```

## 与路由器方案的对比

| 方案 | TUN 模式 | 路由器部署 |
|------|----------|-----------|
| 部署位置 | NAS | 路由器 |
| 性能 | 依赖 NAS 性能 | 依赖路由器性能 |
| 覆盖范围 | 同网段所有设备 | 路由器下所有设备 |
| 复杂度 | 低（Docker 一键） | 高（需要刷固件） |
| 稳定性 | 高 | 依赖路由器固件 |

**推荐**：如果已有 NAS，优先使用 TUN 模式。如果没有 NAS 或需要覆盖更大范围，考虑路由器方案。
