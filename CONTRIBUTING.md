# Contributing

## Git commit conventions

本项目使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式。

### 格式

```
<type>: <subject>

[optional body]
```

### type 说明

| type | 用途 |
|------|------|
| `feat` | C example 新增 |
| `fix` | 修复 example 或构建脚本中的 bug |
| `docs` | 文档变更（README、注释等） |
| `chore` | 维护性工作，不影响源码 |
| `build` | 构建系统变动（build.zig、build.zig.zon、依赖） |
| `refactor` | 重构，无功能变化 |
| `test` | 测试相关 |
| `style` | 代码格式、缩进等 |

### 示例

```
feat: add core_basic_window example

fix: correct window title in core_3d_mode

build: bump raylib to 6.0
chore(deps): update zig dependency hash
```

### 规则

- subject 行不超过 50 字符（中文约 25 字）
- 使用祈使语气，不加句号结尾
- 一个提交只做一件事

## Adding an example

见 `AGENTS.md`。
