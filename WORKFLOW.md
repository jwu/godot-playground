工作流约定

## 工程约定

- 每个测试场景是独立的，可从 `main_menu.tscn` 导航进入，也可单独启动
- 每个测试场景必须包含返回主菜单的"Back"按钮
- 场景与脚本一一对应：`game/scenes/foo.tscn` → `game/scripts/foo.gd`

## 新增测试场景

1. 创建 `game/scenes/your_test.tscn` 和 `game/scripts/your_test.gd`
2. 在 `game/scenes/main_menu.tscn` 的 VBoxContainer 中添加按钮
3. 在 `game/scripts/main_menu.gd` 的 `_ready()` 中连接按钮信号，加载新场景
4. 新场景中添加返回按钮，连接 `get_tree().change_scene_to_file("res://scenes/main_menu.tscn")`

## 以下操作需要确认

- 全量重构
- 删除文件
- 安装/添加插件
- 修改 `game/project.godot`
- 修改 `game/.godot/` 下的文件
- 执行 `git push`

## 常见错误与纠正

| 场景 | 错误做法 | 正确做法 |
|------|---------|---------|
| Retina 屏窗口太小 | 在 `game/project.godot` 中写死 viewport 值 | 用 `DisplayServer.screen_get_max_scale()` 动态适配（见 `game/scripts/main_menu.gd`） |
| 场景连接 | 手动改 `.tscn` 的 uid | 在编辑器中操作，或用脚本中的 `load()` 方法 |
| 添加按钮 | 只写脚本不写场景节点 | 脚本和场景节点要同步修改 |
