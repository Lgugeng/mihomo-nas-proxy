# 故障排查指南

## 常见问题

### 1. 容器启动失败

**症状：** `docker compose up -d` 后容器立即退出

**排查：**
```bash
# 查看详细日志
docker logs mihomo

# 检查配置文件语法
docker run --rm -v ./mihomo:/root/.config/mihomo metacubex/mihomo:Alpha -t
```

**常见原因：**
- `config.yaml` 语法错误
- 端口被占用
- TUN 设备不存在

### 2. 无法连接代理

**症状：** 设置了代理但无法上网

**排查：**
```bash
# 测试 API 是否正常
curl http://127.0.0.1:9090/version

# 测试代理是否工作
curl -x http://127.0.0.1:7890 https://www.google.com

# 检查防火墙
sudo ufw status
```

**解决方案：**
- 确认防火墙放行了 7890/7891/9090 端口
- 确认 `allow-lan: true` 已设置
- 确认客户端代理地址和端口正确

### 3. Web UI 无法访问

**症状：** 访问 `http://NAS_IP:9090/ui/` 返回 404

**排查：**
```bash
# 检查 UI 文件是否存在
ls mihomo/ui/index.html

# 测试 API
curl -I http://127.0.0.1:9090/ui/
```

**解决方案：**
- 重新下载 UI 文件
- 确认 `external-ui: ui` 已在配置中设置

### 4. 订阅更新失败

**症状：** 节点列表为空或过期

**排查：**
```bash
# 查看日志中的错误信息
docker logs mihomo | grep -i "provider"

# 手动测试订阅链接
curl -o /dev/null -s -w "%{http_code}" "你的订阅链接"
```

**解决方案：**
- 检查订阅链接是否有效
- 检查订阅是否过期
- 检查网络连接

### 5. DNS 解析问题

**症状：** 能连接代理但某些网站打不开

**排查：**
```bash
# 测试 DNS
nslookup google.com 127.0.0.1 -port=1053

# 查看 DNS 日志
docker logs mihomo | grep -i "dns"
```

**解决方案：**
- 确认 DNS 配置正确
- 尝试更换 DNS 服务器
- 检查 fake-ip 配置

### 6. 容器健康检查失败

**症状：** Docker 显示容器 unhealthy

**排查：**
```bash
# 检查健康状态
docker inspect --format='{{json .State.Health}}' mihomo

# 手动测试
docker exec mihomo wget --quiet --tries=1 --spider http://127.0.0.1:9090
```

**解决方案：**
- 检查 mihomo 进程是否正常运行
- 检查 API 端口是否可访问
- 查看健康检查日志

## 日志分析

### 启用详细日志

编辑 `mihomo/config.yaml`：

```yaml
log-level: debug  # 改为 debug 获取更多信息
```

### 关键日志关键词

| 关键词 | 含义 |
|--------|------|
| `proxy provider` | 订阅源相关 |
| `dns` | DNS 解析相关 |
| `rule` | 规则匹配相关 |
| `connection` | 连接相关 |
| `error` | 错误信息 |

## 性能优化

### 1. 减少内存占用

```yaml
# 关闭不需要的功能
profile:
  store-fake-ip: false
```

### 2. 优化 DNS 缓存

```yaml
dns:
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
```

### 3. 选择合适的节点

在 Web UI 中使用延迟测试，选择延迟最低的节点。

## 获取帮助

如果以上方法都无法解决问题：

1. 查看 [Mihomo 官方文档](https://wiki.metacubex.one/)
2. 搜索 [GitHub Issues](https://github.com/MetaCubeX/mihomo/issues)
3. 提交新的 Issue，附上：
   - 完整的错误日志
   - 配置文件（去除敏感信息）
   - Docker 版本和系统信息
