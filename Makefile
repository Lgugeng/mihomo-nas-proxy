# ============================================================
# Mihomo NAS Proxy - 常用命令
# ============================================================

.PHONY: help setup up down restart logs status update clean test backup restore monitor monitor-on monitor-off monitor-up monitor-down monitor-logs auto-update

# 默认目标
help: ## 显示帮助信息
	@echo ""
	@echo "  Mihomo NAS Proxy 命令列表"
	@echo "  ========================"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

setup: ## 首次部署（创建目录 + 下载 UI + 生成配置 + 启动）
	@bash scripts/setup.sh

up: ## 启动服务
	docker compose up -d

down: ## 停止服务
	docker compose down

restart: ## 重启服务
	docker compose restart

logs: ## 查看实时日志
	docker logs -f mihomo

status: ## 查看容器状态
	@docker compose ps
	@echo ""
	@echo "  API 状态："
	@curl -s http://127.0.0.1:9090/version 2>/dev/null && echo "" || echo "  ⚠️ API 未响应"

update: ## 更新镜像并重启
	docker compose pull
	docker compose up -d
	@echo ""
	@echo "  ✓ 更新完成"

clean: ## 停止服务并删除运行时数据
	@echo -e "\033[1;33m⚠️  这将删除所有运行时数据（配置、订阅、缓存）\033[0m"
	@read -p "  确认删除？[y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	docker compose down
	rm -rf mihomo/config.yaml mihomo/providers/* mihomo/cache.db mihomo/*.metadb
	@echo "  ✓ 清理完成"

test: ## 测试代理连通性
	@echo "  测试 API..."
	@curl -s http://127.0.0.1:9090/version && echo "" || echo "  ✗ API 未响应"
	@echo "  测试 HTTP 代理..."
	@curl -s -o /dev/null -w "  HTTP 代理: %{http_code}\n" --max-time 5 -x http://127.0.0.1:7890 http://www.gstatic.com/generate_204 || echo "  ✗ HTTP 代理不通"
	@echo "  测试 SOCKS5 代理..."
	@curl -s -o /dev/null -w "  SOCKS5 代理: %{http_code}\n" --max-time 5 -x socks5://127.0.0.1:7891 http://www.gstatic.com/generate_204 || echo "  ✗ SOCKS5 代理不通"

backup: ## 备份配置文件
	@mkdir -p backups
	@cp mihomo/config.yaml backups/config-$$(date +%Y%m%d-%H%M%S).yaml
	@echo "  ✓ 配置已备份到 backups/ 目录"

restore: ## 恢复最近的备份
	@LATEST=$$(ls -t backups/config-*.yaml 2>/dev/null | head -1); \
	if [ -z "$$LATEST" ]; then \
		echo "  ✗ 没有找到备份文件"; \
	else \
		cp "$$LATEST" mihomo/config.yaml; \
		echo "  ✓ 已从 $$LATEST 恢复配置"; \
		docker compose restart; \
	fi

monitor: ## 执行一次健康检查
	@bash scripts/health-check.sh

monitor-on: ## 启用定时健康监控（每小时检查一次）
	@SCRIPT_PATH=$$(cd scripts && pwd)/health-check.sh; \
	CRON_JOB="0 * * * * cd $$(pwd) && bash $$SCRIPT_PATH >> $$(pwd)/mihomo/monitor.log 2>&1"; \
	cron_current=$$(crontab -l 2>/dev/null || true); \
	if echo "$$cron_current" | grep -q "health-check.sh"; then \
		echo "  ⚠️ 定时监控已启用"; \
	else \
		(echo "$$cron_current"; echo "$$CRON_JOB") | crontab -; \
		echo "  ✓ 定时监控已启用（每小时检查一次）"; \
		echo "  日志文件：mihomo/monitor.log"; \
	fi

monitor-off: ## 禁用定时健康监控
	@crontab -l 2>/dev/null | grep -v "health-check.sh" | crontab - 2>/dev/null; \
	echo "  ✓ 定时监控已禁用"

monitor-up: ## 启动监控面板（Prometheus + Grafana）
	docker compose --profile monitoring up -d
	@echo ""
	@echo "  Grafana:    http://localhost:3000"
	@echo "  Prometheus: http://localhost:9091"

monitor-down: ## 停止监控面板
	docker compose --profile monitoring down

monitor-logs: ## 查看监控面板日志
	docker compose --profile monitoring logs -f

auto-update: ## 检查并自动更新 Mihomo 镜像
	@bash scripts/auto-update.sh
