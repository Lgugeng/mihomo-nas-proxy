# 详细部署指南

## 环境要求

- Docker 20.10+
- Docker Compose v2+
- 至少 100MB 可用磁盘空间

## 部署步骤

### 1. 克隆项目

```bash
git clone https://github.com/your-username/clash-proxy.git
cd clash-proxy
```

### 2. 配置环境变量

创建 `.env` 文件：

```bash
cp .env.example .env
```

编辑 `.env`，填入你的订阅链接：

```env
CLASH_SUBSCRIPTION_URL=https://your-subscription-url
MIHOMO_SECRET=your_strong_secret
```

### 3. 运行部署脚本

```bash
bash scripts/setup.sh
```

脚本会自动：
- 检查 Docker 环境
- 创建目录结构
- 下载 MetaCubeXD UI
- 生成配置文件
- 启动服务

### 4. 验证部署

```bash
# 检查容器状态
docker compose ps

# 查看日志
docker logs -f mihomo

# 测试 API
curl http://127.0.0.1:9090/version
```

成功输出示例：
```
Mixed proxy listening at: 7890
SOCKS proxy listening at: 7891
RESTful API listening at: 9090
```

### 5. 访问 Web 管理界面

打开浏览器访问：`http://NAS_IP:9090/ui/`

输入：
- Host: `http://NAS_IP:9090`
- Secret: 你在 `.env` 中设置的密码

## 自定义配置

### 修改代理端口

编辑 `mihomo/config.yaml`：

```yaml
mixed-port: 7890      # HTTP 代理端口
socks-port: 7891      # SOCKS5 代理端口
```

### 修改 Web UI 端口

编辑 `docker-compose.yml`，修改 `external-controller` 端口，并在 `config.yaml` 中同步修改。

### 添加自定义规则

编辑 `mihomo/config.yaml` 的 `rules` 部分：

```yaml
rules:
  # 自定义规则
  - DOMAIN-SUFFIX,example.com,PROXY
  - DOMAIN-KEYWORD,google,PROXY
  - IP-CIDR,1.2.3.4/32,DIRECT
  # ... 其他规则
```

## 多 NAS 部署

如果有多台 NAS，可以在每台上面部署一个实例，通过不同的端口区分。

## 卸载

```bash
docker compose down
rm -rf mihomo/
```
