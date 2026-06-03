#!/bin/bash
# ============================================================
# Mihomo + MetaCubeXD 一键部署脚本
# 用法：bash scripts/setup.sh
# ============================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 项目根目录
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MIHOMO_DIR="$PROJECT_DIR/mihomo"
UI_DIR="$MIHOMO_DIR/ui"
CONFIG_FILE="$MIHOMO_DIR/config.yaml"
ENV_FILE="$PROJECT_DIR/.env"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Mihomo + MetaCubeXD 部署脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# ------------------------------------------------------------
# 0. 加载 .env 文件
# ------------------------------------------------------------
if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}[0/5] 加载 .env 配置...${NC}"
    # 安全加载：只读取 KEY=VALUE 格式，忽略注释和空行
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
        # 去除首尾空格和引号
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs | sed 's/^["'\'']\(.*\)["'\'']$/\1/')
        # 导出环境变量（仅当未手动设置时）
        if [ -z "${!key}" ]; then
            export "$key=$value"
        fi
    done < "$ENV_FILE"
    echo -e "${GREEN}  ✓ .env 配置已加载${NC}"
fi

# ------------------------------------------------------------
# 1. 检查 Docker
# ------------------------------------------------------------
echo -e "${YELLOW}[1/5] 检查 Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误：未安装 Docker，请先安装 Docker${NC}"
    echo -e "${YELLOW}  安装指南：https://docs.docker.com/get-docker/${NC}"
    exit 1
fi
if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}错误：未安装 Docker Compose${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Docker 已安装${NC}"

# ------------------------------------------------------------
# 2. 创建目录结构
# ------------------------------------------------------------
echo -e "${YELLOW}[2/5] 创建目录结构...${NC}"
mkdir -p "$MIHOMO_DIR/providers"
mkdir -p "$UI_DIR"
echo -e "${GREEN}  ✓ 目录创建完成${NC}"

# ------------------------------------------------------------
# 3. 下载 MetaCubeXD UI
# ------------------------------------------------------------
echo -e "${YELLOW}[3/5] 下载 MetaCubeXD UI...${NC}"
UI_URL="https://github.com/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz"

if [ -f "$UI_DIR/index.html" ]; then
    echo -e "${GREEN}  ✓ UI 文件已存在，跳过下载${NC}"
else
    TEMP_FILE=$(mktemp /tmp/mihomo-ui-XXXXXX.tgz)
    if command -v wget &> /dev/null; then
        wget -q --show-progress -O "$TEMP_FILE" "$UI_URL"
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar -o "$TEMP_FILE" "$UI_URL"
    else
        echo -e "${RED}错误：需要 wget 或 curl 来下载 UI${NC}"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    tar -xzf "$TEMP_FILE" -C "$UI_DIR/"
    rm -f "$TEMP_FILE"
    echo -e "${GREEN}  ✓ UI 下载完成${NC}"
fi

# ------------------------------------------------------------
# 4. 生成配置文件
# ------------------------------------------------------------
echo -e "${YELLOW}[4/5] 生成配置文件...${NC}"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}  ✓ 配置文件已存在，跳过生成${NC}"
else
    # 检查订阅链接
    if [ -z "$CLASH_SUBSCRIPTION_URL" ]; then
        echo -e "${RED}错误：请设置订阅链接${NC}"
        echo -e "${YELLOW}  方法1：export CLASH_SUBSCRIPTION_URL='你的订阅链接'${NC}"
        echo -e "${YELLOW}  方法2：在 .env 文件中写入 CLASH_SUBSCRIPTION_URL=你的订阅链接${NC}"
        exit 1
    fi

    # 生成密钥（如果未设置）
    if [ -z "$MIHOMO_SECRET" ]; then
        if command -v openssl &> /dev/null; then
            MIHOMO_SECRET=$(openssl rand -hex 16)
        else
            MIHOMO_SECRET=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' | head -c 32)
        fi
        echo -e "${YELLOW}  未设置密钥，自动生成${NC}"
    fi

    # 使用 awk 替换模板（兼容 macOS 和 Linux）
    awk -v url="$CLASH_SUBSCRIPTION_URL" -v secret="$MIHOMO_SECRET" \
        '{gsub(/CLASH_SUBSCRIPTION_URL/, url); gsub(/CHANGE_ME_TO_STRONG_SECRET/, secret); print}' \
        "$PROJECT_DIR/config/config.yaml.template" > "$CONFIG_FILE"
    echo -e "${GREEN}  ✓ 配置文件生成完成${NC}"
fi

# ------------------------------------------------------------
# 5. 启动服务
# ------------------------------------------------------------
echo -e "${YELLOW}[5/5] 启动服务...${NC}"
cd "$PROJECT_DIR"
if docker compose version &> /dev/null; then
    docker compose up -d
else
    docker-compose up -d
fi
echo -e "${GREEN}  ✓ 服务启动完成${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "  Web 管理界面:  http://localhost:9090/ui/"
echo -e "  HTTP 代理:     http://localhost:7890"
echo -e "  SOCKS5 代理:   socks5://localhost:7891"
echo -e "  API 地址:      http://localhost:9090"
echo ""
echo -e "  查看日志:      make logs"
echo -e "  停止服务:      make down"
echo -e "  更新服务:      make update"
echo ""
echo -e "${YELLOW}⚠️  首次部署请务必：${NC}"
echo -e "  1. 访问 Web UI 修改默认密码"
echo -e "  2. 如需局域网访问，编辑 mihomo/config.yaml 中的 external-controller"
