#!/bin/bash
# ============================================================
# Mihomo 健康监控脚本
# 检查：API 状态、订阅有效性、节点存活数
# 告警：支持 Bark（iOS）和 Telegram Bot 推送
# 用法：bash scripts/health-check.sh
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
API_URL="http://127.0.0.1:9090"
SECRET="${MIHOMO_SECRET:-}"

# 状态标记
HAS_ERROR=0
ALERT_MESSAGES=""

# ------------------------------------------------------------
# 发送告警
# ------------------------------------------------------------
send_alert() {
    local title="$1"
    local body="$2"

    # Bark 推送
    if [ -n "$BARK_URL" ]; then
        curl -s -o /dev/null "${BARK_URL}/${title}/${body}?sound=alarm" 2>/dev/null || true
    fi

    # Telegram 推送
    if [ -n "$TELEGRAM_URL" ]; then
        curl -s -o /dev/null -X POST "$TELEGRAM_URL" \
            -d text="🔔 ${title}\n${body}" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------
# 检查 1：API 状态
# ------------------------------------------------------------
check_api() {
    echo -ne "  检查 API 状态... "
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${API_URL}/version" 2>/dev/null)
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ 正常${NC}"
    else
        echo -e "${RED}✗ 异常 (HTTP $response)${NC}"
        HAS_ERROR=1
        ALERT_MESSAGES="${ALERT_MESSAGES}\n• API 无响应 (HTTP $response)"
    fi
}

# ------------------------------------------------------------
# 检查 2：节点存活数
# ------------------------------------------------------------
check_proxies() {
    echo -ne "  检查节点状态... "

    local auth_header=""
    if [ -n "$SECRET" ]; then
        auth_header="-H \"Authorization: Bearer ${SECRET}\""
    fi

    local proxies_json
    proxies_json=$(curl -s --max-time 10 "${API_URL}/proxies" \
        -H "Authorization: Bearer ${SECRET}" 2>/dev/null)

    if [ -z "$proxies_json" ]; then
        echo -e "${RED}✗ 无法获取节点信息${NC}"
        HAS_ERROR=1
        ALERT_MESSAGES="${ALERT_MESSAGES}\n• 无法获取节点信息"
        return
    fi

    # 统计节点总数（使用 python 或 awk）
    local total=0
    if command -v python3 &> /dev/null; then
        total=$(echo "$proxies_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
proxies = data.get('proxies', {})
count = sum(1 for p in proxies.values() if p.get('type') in ('ss', 'ssr', 'vmess', 'vless', 'trojan', 'hysteria', 'tuic', 'wireguard', 'shadowsocks'))
print(count)
" 2>/dev/null || echo "0")
    fi

    if [ "$total" -gt 0 ]; then
        echo -e "${GREEN}✓ 共 ${total} 个节点${NC}"
    else
        echo -e "${YELLOW}⚠ 未检测到节点（可能订阅未加载）${NC}"
        HAS_ERROR=1
        ALERT_MESSAGES="${ALERT_MESSAGES}\n• 未检测到可用节点"
    fi
}

# ------------------------------------------------------------
# 检查 3：订阅 Provider 状态
# ------------------------------------------------------------
check_providers() {
    echo -ne "  检查订阅状态... "

    local providers_json
    providers_json=$(curl -s --max-time 10 "${API_URL}/providers" \
        -H "Authorization: Bearer ${SECRET}" 2>/dev/null)

    if [ -z "$providers_json" ]; then
        echo -e "${YELLOW}⚠ 无法获取订阅信息${NC}"
        return
    fi

    if command -v python3 &> /dev/null; then
        local status
        status=$(echo "$providers_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
providers = data.get('providers', [])
for p in providers:
    name = p.get('name', 'unknown')
    health = p.get('vehicleType', 'unknown')
    print(f'{name}: {health}')
" 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓ ${status}${NC}"
    else
        echo -e "${GREEN}✓ 已连接${NC}"
    fi
}

# ------------------------------------------------------------
# 检查 4：订阅 URL 有效性（仅检查配置中的 URL）
# ------------------------------------------------------------
check_subscription_url() {
    echo -ne "  检查订阅 URL... "

    local config_file="$PROJECT_DIR/mihomo/config.yaml"
    if [ ! -f "$config_file" ]; then
        echo -e "${YELLOW}⚠ 配置文件不存在${NC}"
        return
    fi

    # 提取第一个订阅 URL
    local sub_url
    sub_url=$(grep -A2 'airport:' "$config_file" | grep 'url:' | head -1 | sed 's/.*url: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/' | xargs)

    if [ -z "$sub_url" ] || [ "$sub_url" = "CLASH_SUBSCRIPTION_URL" ]; then
        echo -e "${YELLOW}⚠ 未找到有效订阅链接${NC}"
        return
    fi

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$sub_url" 2>/dev/null)

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ 有效 (HTTP $http_code)${NC}"
    else
        echo -e "${RED}✗ 无效 (HTTP $http_code)${NC}"
        HAS_ERROR=1
        ALERT_MESSAGES="${ALERT_MESSAGES}\n• 订阅链接无效 (HTTP $http_code)"
    fi
}

# ------------------------------------------------------------
# 主流程
# ------------------------------------------------------------
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Mihomo 健康检查${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

check_api
check_proxies
check_providers
check_subscription_url

echo ""
echo -e "${GREEN}========================================${NC}"

if [ $HAS_ERROR -eq 0 ]; then
    echo -e "${GREEN}  ✓ 所有检查通过${NC}"
else
    echo -e "${RED}  ✗ 发现异常${NC}"
    if [ -n "$ALERT_MESSAGES" ]; then
        send_alert "Mihomo 健康告警" "$(echo -e "$ALERT_MESSAGES")"
        echo -e "${YELLOW}  已发送告警通知${NC}"
    fi
fi

echo -e "${GREEN}========================================${NC}"
echo ""

exit $HAS_ERROR
