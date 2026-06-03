# 贡献指南

感谢你对本项目的关注！以下是参与贡献的方式。

## 提交 Issue

### Bug 报告

请包含以下信息：
- 操作系统和版本（如：飞牛 NAS v1.0、群晖 DSM 7.2）
- Docker 版本（`docker --version`）
- 完整的错误日志（`docker logs mihomo`）
- 你的 `config.yaml`（去除订阅链接和密码等敏感信息）

### 功能建议

请说明：
- 你想要解决什么问题
- 你期望的行为是什么
- 有没有替代方案

## 提交 Pull Request

1. Fork 本仓库
2. 创建你的分支：`git checkout -b feature/your-feature`
3. 提交你的修改：`git commit -m 'Add some feature'`
4. 推送到分支：`git push origin feature/your-feature`
5. 创建 Pull Request

### 分支命名规范

- `feature/xxx` — 新功能
- `fix/xxx` — Bug 修复
- `docs/xxx` — 文档更新
- `refactor/xxx` — 代码重构

### Commit 规范

使用清晰的提交信息：

```
类型: 简短描述

详细说明（可选）
```

类型包括：
- `feat` — 新功能
- `fix` — 修复
- `docs` — 文档
- `style` — 格式
- `refactor` — 重构
- `test` — 测试
- `chore` — 构建/工具

## 开发环境

```bash
# 克隆项目
git clone https://github.com/your-username/mihomo-nas-proxy.git
cd mihomo-nas-proxy

# 复制配置模板
cp .env.example .env
# 编辑 .env 填入测试订阅链接

# 启动开发环境
make setup

# 查看日志
make logs

# 测试
make test
```

## 代码规范

- Shell 脚本使用 `shellcheck` 检查
- YAML 文件保持 2 空格缩进
- 配置文件中的中文注释保持简洁
- 文档使用中文撰写

## 行为准则

- 尊重他人
- 就事论事
- 欢迎新人提问
