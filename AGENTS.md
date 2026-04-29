# AGENTS.md

用于 Godot 4.6 游戏的实验/验证项目，语言为中文。

## 技术栈与约束

- **引擎：** Godot 4.6
- **渲染：** Mobile renderer（非 Forward+/Compatibility）
- **物理：** Jolt Physics（3D）
- **图形 API：** D3D12（Windows）、Metal（macOS）
- **脚本：** GDScript（不使用 C#，除非用户明确要求）
- **依赖管理：** 不使用外部包管理器，插件直接放 `addons/`
- **DIP/Retina：** 设计分辨率统一使用 1280×720，通过 `DisplayServer.screen_get_max_scale()` 自动适配 HiDPI。窗口大小用 `1280 × dpi_scale`，内部视口通过 ContentScale 保持 1280×720。

## 关键入口

```
scenes/main_menu.tscn          ← 主入口，列出所有子测试场景
scripts/main_menu.gd           ← 主菜单脚本，含窗口初始化与 DPI 适配
project.godot                  ← 项目配置（渲染、物理、窗口默认值）
```

## 目录约定

| 目录 | 用途 |
|------|------|
| `scenes/` | Godot 场景文件（`.tscn`） |
| `scripts/` | GDScript 脚本（`.gd`） |
| `assets/` | 纹理、模型、音频等资源 |
| `addons/` | 第三方插件（gdUnit4 等） |
| `.godot/` | 编辑器自动生成，**禁止修改** |

## 工程约定

- 每个测试场景是独立的，可从 `main_menu.tscn` 导航进入，也可单独启动
- 每个测试场景必须包含返回主菜单的"Back"按钮
- 场景与脚本一一对应：`scenes/foo.tscn` → `scripts/foo.gd`
- 默认小步修改、小 diff，不要一次改大量文件
- 修改前先读文件，不要凭推测编辑
- 优先复用已有模式，避免引入新依赖或新插件
- 代码注释用中文

## 新增测试场景的工作流

1. 创建 `scenes/your_test.tscn` 和 `scripts/your_test.gd`
2. 在 `scenes/main_menu.tscn` 的 VBoxContainer 中添加按钮
3. 在 `scripts/main_menu.gd` 的 `_ready()` 中连接按钮信号，加载新场景
4. 新场景中添加返回按钮，连接 `get_tree().change_scene_to_file("res://scenes/main_menu.tscn")`

## 安全边界

**可直接执行：**
- 读取文件
- 搜索/查找文件
- 编辑单个文件

**必须先确认：**
- 删除文件
- 安装/添加插件
- 修改 `project.godot`
- 修改 `.godot/` 下的文件
- 全量重构
- 执行 `git push`

## 常见错误与纠正

| 场景 | 错误做法 | 正确做法 |
|------|---------|---------|
| Retina 屏窗口太小 | 在 `project.godot` 中写死 viewport 值 | 用 `DisplayServer.screen_get_max_scale()` 动态适配（见 `scripts/main_menu.gd`） |
| 场景连接 | 手动改 `.tscn` 的 uid | 在编辑器中操作，或用脚本中的 `load()` 方法 |
| 添加按钮 | 只写脚本不写场景节点 | 脚本和场景节点要同步修改 |

## Git 提交

遵循 `CONTRIBUTING.md` 中的 Conventional Commits 规范。
- subject ≤ 50 字符，祈使语气
- 一个提交只做一件事
- type：`feat` / `fix` / `docs` / `chore` / `refactor` / `style`

## 参考文档

- `CONTRIBUTING.md` — Git 提交规范
- Godot 文档：`~/docs/godot-docs/`
- Godot 源码：`~/src/godot/`
- Godot 项目设置参考：`~/docs/godot-docs/classes/class_projectsettings.rst`

## 遇到困难时

- 先查阅 `~/docs/godot-docs/` 中的相关文档
- 不确定时先提问，不要做大范围猜测性修改
- 涉及引擎内部行为时，查阅 `~/src/godot/` 源码确认
