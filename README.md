# godot-playground

Godot 4.6 实验/验证项目，用于快速搭建和测试游戏机制原型。

## 技术栈

- Godot 4.6 · Mobile renderer · Jolt Physics 3D
- GDScript · D3D12 (Windows) / Metal (macOS)

## 快速开始

用 Godot 4.6 编辑器打开项目根目录，运行 `scenes/main_menu.tscn`。

## 目录

```
scenes/      场景文件（.tscn）
scripts/     脚本文件（.gd）
assets/      纹理、模型、音频等资源
addons/      第三方插件（gdUnit4 等）
```

## 约定

- 设计分辨率 1280×720，自动适配 Retina/HiDPI
- 每个测试场景独立运行，含"Back"按钮返回主菜单
- 新增场景见 `AGENTS.md` 中的工作流说明
- Git 提交遵循 `CONTRIBUTING.md`（Conventional Commits）
