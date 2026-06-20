# DrawLine 实现对照笔记

本文记录三种“画线”实现的差异：Godot 编辑器 3D 视口 grid origin axis、`~/dev/jwu/debug-draw` 的 `DrawLine`，以及本项目 `DebugDraw3D.draw_line`。这些实现名字相近，但几何形态、线宽语义和相机关系不同。

## 对照对象

| 实现 | 位置 | 核心形态 |
|---|---|---|
| Godot 编辑器 3D grid origin axis | `~/src/godot@godotengine/editor/scene/3d/node_3d_editor_plugin.cpp` | 屏幕空间定宽的 3D 锚点线 |
| jwu `DrawLine` | `~/dev/jwu/debug-draw/Runtime/Core/Render/Shapes/LineAndCurve/Line.cs` | 3D 空间矩形面片线 |
| 本项目 `DebugDraw3D.draw_line` | `game/shared/debug_draw_3d/debug_draw_3d.gd` | 3D line primitive |

## Godot 编辑器 3D grid origin axis

Godot 编辑器 3D 视口中的彩色原点轴线不是普通 line primitive，而是专门的 origin line shader + triangle quad mesh + MultiMesh。

源码入口：

```text
editor/scene/3d/node_3d_editor_plugin.cpp
Node3DEditor::_init_indicators()
```

### 几何

编辑器先创建一个 6 顶点 quad 模板：

```cpp
origin_points.resize(6);
origin_points.set(0, Vector3(0.0, -0.5, 0.0));
origin_points.set(1, Vector3(0.0, -0.5, 1.0));
origin_points.set(2, Vector3(0.0, 0.5, 1.0));
origin_points.set(3, Vector3(0.0, -0.5, 0.0));
origin_points.set(4, Vector3(0.0, 0.5, 1.0));
origin_points.set(5, Vector3(0.0, 0.5, 0.0));
```

然后用三角形提交：

```cpp
mesh_add_surface_from_arrays(origin_mesh, RSE::PRIMITIVE_TRIANGLES, d);
```

因此它不是 `PRIMITIVE_LINES`，而是由 shader 展开的 quad。

### 线宽

shader 中将线段端点投影到屏幕空间，并在屏幕空间展开宽度：

```glsl
vec4 clip_a = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(point_a, 1.0));
vec4 clip_b = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(point_b, 1.0));
vec2 screen_a = VIEWPORT_SIZE * (0.5 * clip_a.xy / clip_a.w + 0.5);
vec2 screen_b = VIEWPORT_SIZE * (0.5 * clip_b.xy / clip_b.w + 0.5);

vec2 x_basis = normalize(screen_b - screen_a);
vec2 y_basis = vec2(-x_basis.y, x_basis.x);
float width = 3.0;
```

这意味着 axis 线宽是屏幕空间定宽，大约 3 px，不会随相机距离变化。

### 相机关系

它确实依赖相机，但不是 CPU 端旋转 mesh。shader 使用 `VIEW_MATRIX`、`PROJECTION_MATRIX` 和 `VIEWPORT_SIZE` 动态计算屏幕空间方向。因此相机旋转后，quad 的屏幕展开方向自动变化。

### 长度与实例

编辑器用 MultiMesh 创建 12 个实例：3 个轴 × 4 段。距离分段如下：

```cpp
distances[0] = -1000000.0;
distances[1] = -1000.0;
distances[2] = 0.0;
distances[3] = 1000.0;
distances[4] = 1000000.0;
```

这使原点轴线视觉上几乎无限长。

### 颜色

颜色取自 editor theme：

```cpp
axis_x_color
axis_y_color
axis_z_color
```

默认现代主题大致为：

```cpp
axis_x_color = Color(0.96, 0.20, 0.32)
axis_y_color = Color(0.53, 0.84, 0.01)
axis_z_color = Color(0.16, 0.55, 0.96)
```

同一轴的正负方向使用同色，不像本项目当前原点轴那样负向变暗。

### 与 grid 的关系

普通 grid line 会避开原点轴：

```cpp
// Don't draw lines over the origin if it's enabled.
if (!(origin_enabled && Math::is_zero_approx(position_a))) {
    ...
}
```

这样避免普通灰色网格线覆盖彩色原点轴。

## jwu `DrawLine`

`~/dev/jwu/debug-draw` 的 `DrawLine` 不是 `DrawLine3D(width = 0)`，而是 3D 空间中的矩形面片线。

API 入口：

```text
Runtime/Core/API/Generated/DrawShapes.gen.cs
```

签名：

```csharp
DrawLine(
    float3? start = null,
    float3? end = null,
    float? lineWidth = null,
    float? rotation = null,
    LineStyleSetting? lineStyleSetting = null,
    ColorSetting? color = null,
    bool? isOverhead = null,
    VisibleParams? visibleParams = null)
```

默认值包括：

```csharp
start = default
end = new float3(1, 0, 0)
lineWidth = 0.2f
rotation = 0
lineStyleSetting = LineStyleSetting.DefaultWS
```

### 几何

实现位置：

```text
Runtime/Core/Render/Shapes/LineAndCurve/Line.cs
```

核心逻辑：

```csharp
float3 vector = begin - end;
float3 dir = math.normalize(vector);

quaternion quaternionShape = quaternion.identity;
quaternionShape = math.mul(quaternion.RotateX(-rotation), quaternionShape);
quaternionShape = math.mul(quaternion.RotateZ(math.PI / 2), quaternionShape);
quaternionShape = math.mul(
    MathUtil.FromToRotation(math.forward(), new float3(dir.x, 0, dir.z), math.up()),
    quaternionShape);
quaternionShape = math.mul(MathUtil.FromToRotation(math.up(), vector), quaternionShape);

float3 position = (begin + end) / 2;
Rectangle.Draw(position, quaternionShape, math.length(vector), lineWidth, ...);
```

最终调用 `Rectangle.Draw(...)`，所以这是一条长度为 `|begin - end|`、宽度为 `lineWidth` 的矩形带。

### rotation 语义

`rotation` 通过：

```csharp
quaternion.RotateX(-rotation)
```

先作用在局部空间，再整体对齐到 `begin - end` 方向。视觉上可以理解为：沿线段轴向扭转矩形带，控制宽线面朝向。它不是绕世界 X 轴旋转最终对象，而是成为 line ribbon 对齐过程的一部分。

### 线型

`DrawLine` 使用 `LineStyleSetting`，并交给 `Rectangle.Draw(...)` 的 shader/material 处理点线或虚线。因为几何是矩形面片，线型会作用在有宽度的面片上。

## 本项目 `DebugDraw3D.draw_line`

实现位置：

```text
game/shared/debug_draw_3d/debug_draw_3d.gd
```

签名：

```gdscript
func draw_line(
    from: Vector3,
    to: Vector3,
    color: Color = Color.WHITE,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
```

### 几何

当前实现将线段写入 ImmediateMesh 的 line 顶点缓冲：

```gdscript
vertices.append(a)
colors.append(color)
vertices.append(b)
colors.append(color)
```

它是普通 3D line primitive：

- 没有宽度参数。
- 不生成 quad。
- 不生成圆柱。
- 不做屏幕空间定宽展开。

如果需要粗线，本项目目前使用独立 API：

```gdscript
draw_cylinder_line(from, to, radius, ...)
```

### 线型

本项目 `draw_line` 支持：

```gdscript
LineStyle.DEFAULT
LineStyle.DASH
LineStyle.DOT
```

实现方式是把线切成多个小段：

```gdscript
const DASH_LENGTH := 0.45
const DASH_GAP := 0.25
const DOT_LENGTH := 0.08
const DOT_GAP := 0.22
```

`DASH` 是长虚线；`DOT` 是很短的线段，看起来接近点线。

### overhead 与 layer

本项目使用：

- `overhead`: 是否走 no-depth-test mesh。
- `layer`: bitmask 可见性过滤。

这不同于 jwu 的 `VisibleParams`，也不同于 Godot 编辑器的专用 editor grid layer。

## 差异总表

| 对比项 | Godot 编辑器 grid origin axis | jwu `DrawLine` | 本项目 `draw_line` |
|---|---|---|---|
| 所在空间 | 3D 锚点 + 屏幕空间展开 | 3D 世界空间 | 3D 世界空间 |
| 几何 | triangle quad 模板 | 矩形面片线 | line primitive |
| 线宽 | shader 固定屏幕宽度 `3px` | `lineWidth` 世界宽度 | 无宽度参数 |
| 相机关系 | shader 根据相机投影动态展开 | 普通 3D transform | 普通 3D line |
| 线型 | 无 DASH/DOT API | `LineStyleSetting` | `LineStyle` |
| 颜色 | editor theme axis color | `ColorSetting` | `Color` |
| 正负轴颜色 | 同轴同色 | 由调用者决定 | 当前正向亮色、负向暗色 |
| 长度 | ±1,000,000 分段 | 调用者决定 | 调用者决定 |
| 深度/遮挡 | editor grid layer，专用 shader | `isOverhead` | `overhead` |
| 可见性 | editor layer / origin toggle | `VisibleParams` | `layer / visible_layers` |

## 设计结论

如果目标是“像 Godot 编辑器 grid axis 一样稳定”，普通 `draw_line` 不够。需要新增一种屏幕空间定宽线实现，可能形式包括：

- 专用 shader：输入线段端点，在 shader 里投影并展开宽度。
- 或 CPU 端按当前 camera 计算 billboard quad，再提交 triangle mesh。

如果目标是“像 jwu `DrawLine` 一样有宽度且可旋转”，则应该实现 3D ribbon/rectangle line，参数需要包含：

- `width`
- `rotation`
- `style`
- `color`
- `overhead`

如果目标只是调试用细线，当前 `DebugDraw3D.draw_line` 足够简单，并且已经支持 `DASH/DOT` 与 layer。
