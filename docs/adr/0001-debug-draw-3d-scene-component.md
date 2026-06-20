# DebugDraw3D 使用场景内节点

DebugDraw3D 放在 `game/shared/debug_draw_3d/` 作为可复用场景内节点，而不是 Autoload 全局单例。这样不需要修改 `game/project.godot`，也能让每个测试场景独立拥有调试绘制状态；代价是调用方需要通过场景内唯一节点引用访问它。

## Consequences

- 调用方使用 `%DebugDraw3D` 获取节点，并调用 snake_case 的 `draw_*` 方法。
- DebugDraw3D 通过较晚的 `process_priority` 在 `_process` 中自动 flush 本帧命令，调用方不需要手动 begin/end。
- 第一版不实现 Unity 的 `VisibleParams` 全量语义，只保留总开关和 layer 过滤。
