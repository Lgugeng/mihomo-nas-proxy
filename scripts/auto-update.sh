#!/bin/bash
# ============================================================
# Mihomo 自动更新脚本
# 检查新镜像 → 拉取 → 比对 → 重启 → 通知
# 用法：bash scripts/auto-update.sh
# ============================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 项目根目录
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

# 加载 .env
if [ -f "$ENV_FILE" ]; then
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs | sed 's/^["'\'']\(.*\)["'\'']$/\1/')
        if [ -z "${!key}" ]; then
            export "$key=$value"
        fi
    done < "$ENV_FILE"
fi

# 配置
IMAGE="docker.io/metacubex/mihomo:Alpha"
BARK_URL="${BARK_URL:-}"
TELEGRAM_URL="${TELEGRAM_URL:-}"

# ------------------------------------------------------------
# 发送通知
# ------------------------------------------------------------
send_notification() {
    local title="$1"
    local body="$2"

    if [ -n "$BARK_URL" ]; then
        curl -s -o /dev/null "${BARK_URL}/${title}/${body}" 2>/dev/null || true
    fi

    if [ -n "$TELEGRAM_URL" ]; then
        curl -s -o /dev/null -X POST "$TELEGRAM_URL" \
            -d text="🔄 ${title}\n${body}" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------
# 主流程
# ------------------------------------------------------------
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Mihomo 自动更新检查${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 获取当前镜像 digest
echo -ne "  获取当前镜像信息... "
CURRENT_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE" 2>/dev/null | cut -d@ -f2 || echo "unknown")
if [ "$CURRENT_DIGEST" = "unknown" ]; then
    echo -e "${YELLOW}⚠ 无法获取当前镜像信息${NC}"
else
    echo -e "${GREEN}✓ ${CURRENT_DIGEST:0:16}...${NC}"
fi

# 拉取最新镜像
echo -ne "  拉取最新镜像... "
docker pull "$IMAGE" > /dev/null 2>&1
NEW_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE" 2>/dev/null | cut -d@ -f2 || echo "unknown")
echo -e "${GREEN}✓ ${NEW_DIGEST:0:16}...${NC}"

# 比对 digest
echo ""
if [ "$CURRENT_DIGEST" = "$NEW_DIGEST" ]; then
    echo -e "${GREEN}  ✓ 镜像已是最新，无需更新${NC}"
    exit 0
fi

echo -e "${YELLOW}  ⚡ 发现新版本！${NC}"
echo -e "  旧版本: ${CURRENT_DIGEST:0:16}..."
echo -e "  新版本: ${NEW_DIGEST:0:16}..."
echo ""

# 重启服务
echo -ne "  重启服务... "
cd "$PROJECT_DIR"
if docker compose version &> /dev/null; then
    docker compose up -d > /dev/null 2>&1
else
    docker-compose up -d > /dev/null 2>&1
fi
echo -e "${GREEN}✓${NC}"

# 等待服务就绪
echo -ne "  等待服务就绪... "
sleep 5
for i in $(seq 1 12); do
    if curl -s --max-time 2 http://127.0.0.1:9090/version > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        break
    fi
    if [ "$i" -eq 12 ]; then
        echo -e "${RED}✗ 服务启动超时${NC}"
        send_notification "Mihomo 更新失败" "服务启动超时，请手动检查"
        exit 1
    fi
    sleep 5
done

# 发送通知
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ 更新完成${NC}"
echo -e "${GREEN}========================================${NC}"

send_notification "Mihomo 已更新" "旧: ${CURRENT_DIGEST:0:16}\n新: ${NEW_DIGEST:0:16}\n服务已重启"
