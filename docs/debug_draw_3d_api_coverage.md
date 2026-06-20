# DebugDraw3D API 覆盖样例方案

本文记录 `game/scenes/debug_draw_3d.tscn` 的样例扩展方案。目标是让 3D 调试绘制场景像 `debug_draw_2d.tscn` 一样，成为可浏览的公开 API 覆盖样例，而不是完整截图测试矩阵。

## 目标

- 覆盖 `DebugDraw3D` 共享节点的公开绘制能力。
- 每个非别名 `draw_*` API 至少有一个可观察样例。
- 关键枚举值至少出现一次，并在重要 API 上做代表性对比。
- 保持单场景、FreeCamera 浏览、Esc 返回主菜单的现有工作流。
- 不修改 `game/project.godot`，不新增插件，不拆成多个子场景。

## 非目标

- 不做所有 API × 所有枚举值的完整笛卡尔积。
- 不做已经移除的旧别名 API 展品。
- 不把空间标签当成 DebugDraw3D 自身的绘制能力。
- 不新增截图基准或像素级断言。

## 覆盖边界

### 公开绘制 API

需要展示的非别名 API：

- `draw_line`
- `draw_polyline`
- `draw_curve`
- `draw_arrow`
- `draw_arrow_curve`
- `draw_flat_circle`
- `draw_flat_rect`
- `draw_flat_triangle`
- `draw_cylinder_line`
- `draw_cylinder_polyline`
- `draw_cylinder_curve`
- `draw_cylinder_arrow_curve`
- `draw_arrow_3d`
- `draw_box`
- `draw_sphere`
- `draw_cylinder`
- `draw_capsule`
- `draw_cone`

旧别名 API 不再保留：

`draw_line_3d` 已移除：细线使用 `draw_line`，有厚度的 3D 线使用 `draw_cylinder_line`。
`draw_polyline_3d` 已移除：细折线使用 `draw_polyline`，有厚度的 3D 折线使用 `draw_cylinder_polyline`。
`draw_3d_arrow` 已移除：体积箭头使用 `draw_arrow_3d`。

### 枚举覆盖

采用代表性覆盖：每个枚举值至少出现一次，但不对每个 API 展示全组合。

- `MeshType`: `SOLID`、`WIREFRAME`、`MIXED`
- `LineStyle`: `DEFAULT`、`DASH`、`DOT`
- `CurveType`: `BEZIER`、`ROUND_CORNER`、`CLOSED_ROUND_CORNER`、`CATMULL_ROM`、`LINES`、`HERMITE`
- `ArrowPointType`: `NONE`、`TRIANGLE`、`PRISMATIC`、`CIRCLE`

### 行为覆盖

- `overhead`: 做一组深度测试与置顶绘制对比。
- `layer/visible_layers`: 提供数字键切换 layer 可见性，并在 UI 中显示当前 layer 状态。
- `debug_visible`: 保持现有默认展示，不作为主要交互项；如需要可后续加一个总开关。

## 场景组织

继续使用单个 `debug_draw_3d.tscn`：

- 保留 `FreeCamera`、`EndlessGrid3D`、`DebugDraw3D`、`UI/InfoLabel`。
- 在脚本中创建 `Label3D` 空间标签，不手写大量 `.tscn` 节点。
- 用固定分区坐标摆放展品，避免运行时布局系统。

建议分区：

| 分区 | 位置建议 | 内容 |
| --- | --- | --- |
| 线段与样式 | 左前 | `draw_line`、`draw_polyline`，展示默认、虚线、点线 |
| 曲线 | 中前 | `draw_curve` 全部 `CurveType` 代表样例 |
| 箭头 | 右前 | `draw_arrow`、`draw_arrow_curve`、`draw_arrow_3d`，覆盖箭头头型 |
| 平面形状 | 左后 | `draw_flat_circle`、`draw_flat_rect`、`draw_flat_triangle`，覆盖 `MeshType` |
| 体积形状 | 中后 | `draw_box`、`draw_sphere`、`draw_cylinder`、`draw_capsule`、`draw_cone` |
| 管线/粗线 | 右后 | `draw_cylinder_line`、`draw_cylinder_polyline`、`draw_cylinder_curve`、`draw_cylinder_arrow_curve` |
| 渲染行为 | 中央或靠近相机 | `overhead` 对比、layer 开关样例 |

## 空间标签

空间标签使用 `Label3D`，作为样例说明文字，不属于 DebugDraw3D API 覆盖对象。

推荐属性：

- `billboard = BaseMaterial3D.BILLBOARD_ENABLED`
- `fixed_size = true`
- `no_depth_test = true`
- `shaded = false`
- `font_size` 适中，`pixel_size` 控制屏幕尺寸
- 分区标题使用更醒目的颜色，单个展品标签使用浅色

标签策略：

- 每个分区一个标题标签。
- 每个展品一个短标签，写 API 名和关键参数，例如 `draw_curve: HERMITE`。
- 已移除的旧别名不再写入展品标签。

## 交互

现有交互保持不变：

- 右键进入 Freelook，`WASD/QE` 移动。
- 中键轨道旋转，中键 + Shift 平移，中键 + Ctrl 缩放。
- Esc 在 Freelook 中退出 Freelook，否则返回主菜单。

新增建议：

- `1`：切换 layer 1。
- `2`：切换 layer 2。
- `3`：切换 layer 4。
- UI 文本追加显示当前可见 layer，例如 `Layers: 1:on 2:off 4:on`。

数字键不与 FreeCamera 的现有移动输入冲突。

## 实现步骤

1. 在 `game/scenes/debug_draw_3d.gd` 中抽出分区绘制函数，补齐公开 API 样例。
2. 增加空间标签创建与复用逻辑，避免每帧创建节点。
3. 增加 layer 状态与数字键切换逻辑，调用 `_debug_draw.set_layer_enabled()`。
4. 更新 UI 信息文本，包含相机信息、layer 状态和基础操作提示。
5. 更新 `game/tests/debug_draw_3d_test.gd`，验证场景包含空间标签容器、绘制后有 surface、layer 切换会改变 `visible_layers`。

## 验收标准

- 打开 `debug_draw_3d.tscn` 后，能在单场景内看到所有非别名公开 `draw_*` API 的样例。
- `MeshType`、`LineStyle`、`CurveType`、`ArrowPointType` 的所有值都至少被展示一次。
- 空间标签始终可读，不被样例几何遮挡。
- 数字键可以切换 layer 样例的可见性，UI 能显示当前状态。
- 现有 FreeCamera 操作和 Esc 返回逻辑不被破坏。
