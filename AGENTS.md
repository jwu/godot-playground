# AGENTS.md

用于 Godot 4.6 游戏的实验/验证项目，语言为中文。

## 技术栈

- **引擎：** Godot 4.6
- **渲染：** Mobile renderer（非 Forward+/Compatibility）
- **物理：** Jolt Physics（3D）
- **图形 API：** D3D12（Windows）、Metal（macOS）
- **脚本：** GDScript（不使用 C#，除非用户明确要求）
- **依赖管理：** 不使用外部包管理器，插件直接放 `addons/`
- **DIP/Retina：** 设计分辨率统一使用 1280×720，通过 `DisplayServer.screen_get_max_scale()` 自动适配 HiDPI。窗口大小用 `1280 × dpi_scale`，内部视口通过 ContentScale 保持 1280×720。

## 快速上手

### 入口

```
game/scenes/main_menu.tscn     ← 主入口，列出所有子测试场景
game/scripts/main_menu.gd      ← 主菜单脚本，含窗口初始化与 DPI 适配
game/project.godot             ← 项目配置（渲染、物理、窗口默认值）
```

### 常用命令

```bash
just init  # 初始化工程
just test  # 单元测试
just fmt   # 代码格式化
just lint  # 代码校验
```

## 目录结构

```
project/
  ├── .git/                   # git 版本管理
  ├── .githooks/              # git hooks
  ├── .pi/                    # pi agent 相关
  ├── rules/                  # Agent 规则
  │   ├── coding.md             # 代码编码规范
  │   ├── commit.md             # git 提交规范
  │   └── assets.md             # 资产命名规范
  │
  ├── docs/                   # 文档
  │   ├── ...
  │   ├── glossary.md           # 词汇表
  │   └── index.md              # 索引
  │
  ├── game/                   # godot 项目
  │   ├── .godot/               # godot 本地配置
  │   ├── addons/               # godot 扩展
  │   ├── tools/                # godot 项目工具
  │   ├── shared/               # 共享资产
  │   ├── scenes/               # 入口场景（和启动关联）
  │   ├── entities/             # 游戏实体
  │   ├── systems/              # 游戏系统
  │   ├── levels/               # 游戏关卡
  │   ├── assets/               # 美术资产、音效、特效等
  │   ├── playtests/            # 游戏体验测试
  │   ├── tests/                # 单元测试
  │   └── project.godot
  │
  ├── .editorconfig
  ├── .gitattributes
  ├── .gitignore
  ├── cog.toml                # cocogitto 配置文件
  ├── justfile                # just 配置文件
  ├── AGENTS.md               # Agent 的协作规则
  ├── WORKFLOW.md             # 项目的工作流程
  ├── CHANGELOG.md            # 版本更新日志
  └── README.md               # 项目简介
```

## 工作流程

- 动手前请先阅读 `WORKFLOW.md`

### 问题追踪 Issue tracker

Issue 在 GitHub Issues 中跟踪；外部 PR 不作为 triage 请求入口。详见 `docs/agents/issue-tracker.md`。

### 标签分类 Triage labels

Triage 标签使用默认的五类规范词汇。详见 `docs/agents/triage-labels.md`。

### 领域文档 Domain docs

领域文档使用 single-context 布局。详见 `docs/agents/domain.md`。

- `CONTEXT.md` 中的词汇条目统一使用 `中文（English）` 形式，例如 `调试绘制（Debug Draw）`。

## 协作规则

### 编辑

- 修改前先读文件，不要凭推测编辑
- 优先小步编辑，避免大改结构或覆盖大量原文
- 编辑 gdscript 遵守 `rules/coding.md`
    - 代码注释用中文
    - 优先复用已有模式，避免引入新依赖或新插件
- 编辑 md 文档使用使用简洁中文
    - 嵌套列表的子级使用 4 空格缩进
    - 引用文件夹时不要使用 `[[wikilink]]`，统一使用 ``文件夹名/`` 形式
    - Markdown 表格内的 `[[wikilink|alias]]` 需写成 `[[wikilink\|alias]]`，否则 `|` 会被当作表格分隔符导致表格断裂

### 创建

- N/A

### 搜索

- 默认不全库扫描，按任务读取相关代码、文档和资源。
- 搜索文件内容优先使用 tool `grep`、`find` 和 `ls`
- 获取互联网信息优先使用 tool `webfetch`
- 以上 tool 失败后，再考虑
    - 获取 GitHub 仓库信息优先使用 `gh`
    - 获取 YouTube 等视频信息优先使用 `yt-dlp`
- Godot 相关资料
    - Godot 文档：`~/docs/godot-docs/`
    - Godot 源码：`~/src/godot@godotengine/`
- 遇到 Godot 相关问题时
    - 先查阅 `~/docs/godot-docs/`
    - 涉及引擎内部行为时，查阅 `~/src/godot@godotengine/` 源码确认
    - 不确定时先提问，不要做大范围猜测性修改

### 提交

- Git commit message 使用 Conventional Commits 格式：`type(scope): 中文描述`
- commit message 的描述部分必须使用中文，不使用纯英文描述
- 按改动内容分批次提交，避免把无关改动混进同一个 commit

### 严禁

- 增加、删除、重命名 `rules/` 中的文件夹

### 以下操作必须先征求用户同意

- 大规模移动、重命名文件
- 删除文件
- 覆盖大量原始内容
- 引入新的目录体系
- 安装/添加插件
- 批量重构
- 提交 Git
- 修改 `game/project.godot`
- 修改 `game/.godot/` 下的文件
