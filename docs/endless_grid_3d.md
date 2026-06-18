# EndlessGrid3D

`EndlessGrid3D` 是一个用于 3D 调试场景的无限网格实体，位于：

```text
game/entities/endless_grid_3d.tscn
game/entities/endless_grid_3d.gd
game/entities/endless_grid_3d.gdshader
```

它当前被 `game/scenes/debug_draw_3d.tscn` 作为子场景直接实例化。

## 目标

`EndlessGrid3D` 的目标是提供一个接近编辑器视图网格的 3D debug grid：

- 看起来接近无限延伸。
- 网格会跟随当前相机的 XZ 坐标移动。
- 使用 shader 按像素绘制网格线，而不是生成大量线段。
- 根据屏幕空间导数自动切换 LOD，减少远处摩尔纹。
- 支持细线、粗线、距离渐隐和低角度渐隐。

实现思路参考：

- The Machinery 的 grid renderer 文章。
- OGLDEV 的 The Endless Grid 视频。

## 核心思路

`EndlessGrid3D` 并不是真的创建无限多条线。

它只创建一个很大的 XZ 平面：

```text
两个三角形 = 6 个顶点
```

然后在 shader 中根据每个像素的世界坐标计算：

- 这个像素是否靠近网格线。
- 当前应该使用哪个 LOD 的格子大小。
- 应该使用细线颜色还是粗线颜色。
- 当前像素 alpha 应该是多少。

同时，脚本每帧让这个平面跟随当前 viewport camera 的 XZ 位置：

```gdscript
global_position = Vector3(camera.global_position.x, 0.0, camera.global_position.z)
```

因此相机水平移动时，网格平面也跟着移动，视觉上形成 endless grid。

## 文件职责

### `endless_grid_3d.tscn`

实体入口场景。

```text
EndlessGrid3D : MeshInstance3D
```

脚本挂载：

```text
res://entities/endless_grid_3d.gd
```

### `endless_grid_3d.gd`

负责运行时构建 mesh 和绑定 shader。

关键行为：

1. `_ready()` 中构建 6 顶点 `ArrayMesh`。
2. 创建 `ShaderMaterial` 并绑定 `endless_grid_3d.gdshader`。
3. 把导出的参数同步给 shader。
4. `_process()` 中跟随当前 viewport camera。

mesh 构建方式：

```gdscript
var vertices := PackedVector3Array([
  Vector3(-half, 0.0, -half),
  Vector3(half, 0.0, -half),
  Vector3(half, 0.0, half),
  Vector3(-half, 0.0, -half),
  Vector3(half, 0.0, half),
  Vector3(-half, 0.0, half),
])
```

### `endless_grid_3d.gdshader`

负责真正的网格绘制。

它使用 spatial shader：

```glsl
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, fog_disabled;
```

主要逻辑包括：

- 计算世界空间 XZ 坐标。
- 使用 `dFdx()` / `dFdy()` 估算屏幕空间导数。
- 根据导数计算 LOD。
- 分别计算 `lod0` / `lod1` / `lod2` 的网格线 alpha。
- 根据 LOD alpha 混合细线和粗线颜色。
- 根据相机距离和观察角度调整透明度。

## LOD 计算

LOD 的关键不是直接使用相机距离，而是使用：

> 一个屏幕像素对应多少 grid-space。

shader 中通过导数估算：

```glsl
vec2 dudv = vec2(
  length(vec2(dFdx(uv.x), dFdy(uv.x))),
  length(vec2(dFdx(uv.y), dFdy(uv.y)))
);
```

然后计算：

```glsl
float lod_level = max(
  0.0,
  log((derivative_length * min_pixels_between_cells) / safe_cell_size) / log(10.0) + 1.0
);
```

含义：

- 网格在屏幕上越密，`derivative_length` 越大。
- 当 cell 在屏幕上小于最小像素间隔时，LOD 提高。
- 每一级 LOD 的 cell size 扩大 10 倍。

当前使用三层 cell size：

```glsl
float lod0_cell_size = safe_cell_size * pow(10.0, lod_power);
float lod1_cell_size = lod0_cell_size * 10.0;
float lod2_cell_size = lod1_cell_size * 10.0;
```

## 网格线 alpha

`grid_line_alpha()` 用于判断当前像素是否靠近网格线：

```glsl
float grid_line_alpha(vec2 uv, float current_cell_size, vec2 dudv) {
  // 贴近 The Machinery：用 grid-space 导数作为屏幕空间线宽，
  // 再通过 mod() 构造每个 cell 边界附近的 coverage alpha。
  vec2 line_width = max(dudv * line_width_pixels, vec2(0.00001));
  vec2 coverage = 1.0 - abs(
    clamp(mod(uv, vec2(current_cell_size)) / line_width, vec2(0.0), vec2(1.0)) * 2.0 - 1.0
  );
  return max(coverage.x, coverage.y);
}
```

这个函数返回：

- `0.0`：不显示网格线。
- `1.0`：完全显示网格线。
- `0.0 ~ 1.0`：网格线边缘的抗锯齿渐变。

## 渐隐

### 距离渐隐

网格越靠近平面边缘越透明：

```glsl
float distance_opacity = 1.0 - clamp(
  length(world_position.xz - CAMERA_POSITION_WORLD.xz) / half_grid_size,
  0.0,
  1.0
);
```

由于平面跟随 camera XZ 移动，这个渐隐始终以当前相机为中心。

### 低角度渐隐

视线越贴近平面，网格越透明：

```glsl
float grazing_opacity = 1.0;
if (enable_grazing_opacity) {
  vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_position);
  grazing_opacity = 1.0 - pow(1.0 - abs(dot(view_dir, vec3(0.0, 1.0, 0.0))), 16.0);
}
```

这可以减少贴地视角下远处网格的视觉噪声。需要对比 OGLDEV 基础版时，可以关闭 `enable_grazing_opacity`。

## 导出参数

`endless_grid_3d.gd` 暴露以下参数：

| 参数 | 默认值 | 说明 |
|---|---:|---|
| `follow_viewport_camera` | `true` | 是否自动跟随当前 viewport camera |
| `grid_size` | `2000.0` | 网格平面尺寸 |
| `cell_size` | `1.0` | 基础 cell 大小 |
| `min_pixels_between_cells` | `2.0` | LOD 切换使用的最小像素间距 |
| `line_width_pixels` | `2.0` | 网格线屏幕空间宽度倍率 |
| `enable_grazing_opacity` | `true` | 是否启用低角度渐隐 |
| `thin_line_color` | `(0.3, 0.3, 0.3, 0.5)` | 细线颜色 |
| `thick_line_color` | `(0.4, 0.4, 0.4, 0.7)` | 粗线颜色 |

## 在场景中使用

推荐直接把实体作为子场景实例加入目标场景：

```text
DebugDraw3D
├── Camera3D
├── EndlessGrid3D
├── DrawMesh
└── UI
```

对应 `.tscn` 写法：

```ini
[ext_resource type="PackedScene" path="res://entities/endless_grid_3d.tscn" id="2"]

[node name="EndlessGrid3D" parent="." instance=ExtResource("2")]
```

`EndlessGrid3D` 会在 `_ready()` 中自行构建 mesh，在 `_process()` 中自动跟随当前 viewport camera。

## 和 DebugDraw3D 的关系

`DebugDraw3D` 场景中有两套绘制：

1. `EndlessGrid3D`
   - 用 shader 绘制无限网格。
   - 负责 XZ grid。

2. `DrawMesh`
   - 使用 `ImmediateMesh` 绘制调试线框。
   - 负责坐标轴、线段、线框球体、线框立方体、点标记、方向射线等。

这样避免用 `ImmediateMesh` 生成大量 grid 线段，同时保留 debug draw 演示内容。

## 限制与注意事项

1. **不是真正无限**

   它仍然是有限尺寸 plane，只是跟随 camera，并通过渐隐营造 endless 效果。

2. **依赖当前 viewport camera**

   默认使用：

   ```gdscript
   get_viewport().get_camera_3d()
   ```

   如果一个 viewport 中有多个 camera，需要确保目标 camera 是 current。

3. **透明排序可能影响视觉**

   grid 使用 `blend_mix`。如果和其他透明物体或贴近地面的线框重叠，可能出现排序差异。

4. **LOD 是 per-pixel shader 计算**

   测试只能覆盖场景加载、mesh 构建和参数绑定，视觉质量需要在运行时观察。

## 测试

相关测试：

```text
game/tests/endless_grid_3d_test.gd
game/tests/debug_draw_3d_test.gd
```

运行：

```bash
cd game
bash ./addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot -a res://tests/endless_grid_3d_test.gd
bash ./addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot -a res://tests/debug_draw_3d_test.gd
```

覆盖内容：

- `EndlessGrid3D` 能构建 6 顶点 `ArrayMesh`。
- 能创建并绑定 `ShaderMaterial`。
- `follow_camera()` 能把 grid 锁定到 camera XZ。
- `DebugDraw3D` 场景包含 `EndlessGrid3D` 子场景。

## 参考

- The Machinery Blog Archive: [Borderland Between Rendering and Editor - Part 1](https://ruby0x1.github.io/machinery_blog_archive/post/borderland-between-rendering-and-editor-part-1/index.html)
- OGLDEV: [The Endless Grid](https://www.youtube.com/watch?v=RqrkVmj-ntM)
- OGLDEV source: [tutorial54_youtube](https://github.com/emeiri/ogldev/tree/master/tutorial54_youtube)
