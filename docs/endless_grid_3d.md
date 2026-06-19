# EndlessGrid3D

`EndlessGrid3D` 是 `game/entities/endless_grid_3d.tscn` 里的 3D 调试网格实体，当前由 `game/scenes/debug_draw_3d.tscn` 直接实例化。

## 做什么

- 用 6 个顶点生成一个 XZ 平面。
- 在 shader 中按像素绘制网格线和 LOD。
- 每帧跟随当前 viewport camera 的 XZ 坐标，看起来像无限网格。

## 用法

把子场景加到需要调试网格的 3D 场景里：

```text
DebugDraw3D
├── FreeCamera
├── EndlessGrid3D
└── DrawMesh
```

常用导出参数：

| 参数 | 用途 |
|---|---|
| `grid_size` | 平面尺寸 |
| `cell_size` | 基础格子大小 |
| `min_pixels_between_cells` | LOD 切换密度 |
| `line_width_pixels` | 线宽 |
| `debug_lod_colors` | 用颜色显示 LOD |

## 注意

它不是真无限，只是大平面 + 跟随相机 + 边缘渐隐。视觉细节看 `game/entities/endless_grid_3d.gdshader`，别在文档里复制一遍。
