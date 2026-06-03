# 更新日志

本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

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
