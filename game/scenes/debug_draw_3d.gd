extends Node3D
## DebugDraw3D：3D 调试绘制演示，FreeCamera + 共享 DebugDraw3D 节点
##
## 相机操作由 res://entities/free_camera.tscn 提供。
## Esc 在 Freelook 中退出 Freelook，否则返回主菜单。

const DebugDraw3DNode := preload("res://shared/debug_draw_3d/debug_draw_3d.gd")
const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const GRID_HALF := 30
const LABEL_FONT_SIZE := 18
const LABEL_PIXEL_SIZE := 0.003
const INFO_PREFIX := "DebugDraw3D API 覆盖样例\n基础操作：中键旋转 / Shift+中键平移 / 滚轮缩放 / 右键 Freelook / Esc 返回\n"

var _last_info_text := ""
var _spatial_labels: Node3D

@onready var _free_camera: FreeCamera = $FreeCamera
@onready var _info_label: Label = $UI/InfoLabel
@onready var _debug_draw: DebugDraw3DNode = %DebugDraw3D


func _ready() -> void:
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(roundi(DESIGN_WIDTH * dpi_scale), roundi(DESIGN_HEIGHT * dpi_scale))
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
  _setup_spatial_labels()
  _update_info_label()


func _process(_delta: float) -> void:
  _update_info_label()
  _draw_demos()


func _input(event: InputEvent) -> void:
  if event.is_action_pressed(&"ui_cancel"):
    if _free_camera.is_freelook_active():
      _free_camera.set_freelook_active(false)
    else:
      get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _update_info_label() -> void:
  var text := INFO_PREFIX + _free_camera.get_info_text()
  if text != _last_info_text:
    _info_label.text = text
    _last_info_text = text


func _draw_demos() -> void:
  _draw_axes()
  _draw_line_demos()
  _draw_curve_demos()
  _draw_flat_shape_demos()
  _draw_volume_demos()
  _draw_arrow_demos()


func _draw_axes() -> void:
  var axis_len := float(GRID_HALF) + 2.0
  _debug_draw.draw_line(Vector3(-axis_len, 0.0, 0.0), Vector3(axis_len, 0.0, 0.0), Color.RED)
  _debug_draw.draw_line(Vector3(0.0, -axis_len, 0.0), Vector3(0.0, axis_len, 0.0), Color.GREEN)
  _debug_draw.draw_line(Vector3(0.0, 0.0, -axis_len), Vector3(0.0, 0.0, axis_len), Color.BLUE)


func _draw_line_demos() -> void:
  var origin := Vector3(-20.0, 0.0, -20.0)
  _debug_draw.draw_line(origin, origin + Vector3(8.0, 0.0, 0.0), Color.WHITE)
  _debug_draw.draw_line(origin, origin + Vector3(0.0, 6.0, 0.0), Color.RED, DebugDraw3DNode.LineStyle.DASH)
  _debug_draw.draw_line(origin, origin + Vector3(0.0, 0.0, 8.0), Color.GREEN, DebugDraw3DNode.LineStyle.DOT)
  _debug_draw.draw_polyline(
    PackedVector3Array(
      [
        origin + Vector3(0.0, 0.0, 8.0),
        origin + Vector3(3.0, 2.0, 6.0),
        origin + Vector3(6.0, 1.0, 4.0),
        origin + Vector3(8.0, 6.0, 0.0),
      ],
    ),
    Color.DEEP_SKY_BLUE,
  )
  _debug_draw.draw_cylinder_line(
    origin + Vector3(10.0, 0.0, 0.0),
    origin + Vector3(10.0, 5.0, 5.0),
    0.12,
    Color.ORANGE,
    DebugDraw3DNode.MeshType.MIXED,
  )
  _debug_draw.draw_cylinder_polyline(
    PackedVector3Array(
      [
        origin + Vector3(12.0, 0.0, 0.0),
        origin + Vector3(13.0, 2.0, 2.0),
        origin + Vector3(16.0, 1.0, 4.0),
      ],
    ),
    0.1,
    Color.LIGHT_GREEN,
  )


func _draw_curve_demos() -> void:
  var base_points := PackedVector3Array(
    [
      Vector3(-20.0, 0.0, 6.0),
      Vector3(-16.0, 4.0, 8.0),
      Vector3(-12.0, 1.0, 12.0),
      Vector3(-8.0, 5.0, 10.0),
    ],
  )
  var curve_specs: Array[Dictionary] = [
    { type = DebugDraw3DNode.CurveType.BEZIER, offset = Vector3(0.0, 0.0, 0.0), color = Color.CYAN },
    {
      type = DebugDraw3DNode.CurveType.ROUND_CORNER,
      offset = Vector3(0.0, 0.0, 4.0),
      color = Color.LIGHT_GREEN,
    },
    {
      type = DebugDraw3DNode.CurveType.CLOSED_ROUND_CORNER,
      offset = Vector3(0.0, 0.0, 8.0),
      color = Color.ORANGE,
    },
    {
      type = DebugDraw3DNode.CurveType.CATMULL_ROM,
      offset = Vector3(10.0, 0.0, 0.0),
      color = Color.YELLOW,
    },
    {
      type = DebugDraw3DNode.CurveType.LINES,
      offset = Vector3(10.0, 0.0, 4.0),
      color = Color.WHITE,
    },
    {
      type = DebugDraw3DNode.CurveType.HERMITE,
      offset = Vector3(10.0, 0.0, 8.0),
      color = Color.MAGENTA,
    },
  ]
  for spec: Dictionary in curve_specs:
    _debug_draw.draw_curve(
      _offset_points(base_points, spec["offset"]),
      spec["color"],
      int(spec["type"]),
    )

  var arrow_points := _offset_points(base_points, Vector3(0.0, 0.0, 14.0))
  arrow_points.append(Vector3(-4.0, 2.0, 26.0))
  _debug_draw.draw_arrow_curve(
    arrow_points,
    Color.YELLOW,
    DebugDraw3DNode.CurveType.CATMULL_ROM,
    DebugDraw3DNode.ArrowPointType.PRISMATIC,
  )
  _debug_draw.draw_cylinder_curve(
    _offset_points(base_points, Vector3(10.0, 0.0, 14.0)),
    0.08,
    Color(0.4, 1.0, 0.6, 0.8),
    DebugDraw3DNode.CurveType.BEZIER,
    DebugDraw3DNode.MeshType.MIXED,
  )
  _debug_draw.draw_cylinder_arrow_curve(
    arrow_points,
    0.08,
    Color(1.0, 0.6, 0.2, 0.85),
    DebugDraw3DNode.CurveType.CATMULL_ROM,
    DebugDraw3DNode.ArrowPointType.PRISMATIC,
  )


func _draw_flat_shape_demos() -> void:
  _debug_draw.draw_flat_circle(
    Vector3(10.0, 0.05, 10.0),
    3.0,
    Vector3.UP,
    Color(0.2, 0.8, 1.0, 0.35),
    DebugDraw3DNode.MeshType.MIXED,
  )
  _debug_draw.draw_flat_rect(
    Vector3(18.0, 2.0, 8.0),
    Vector2(5.0, 3.0),
    Vector3.RIGHT,
    Vector3.UP,
    Color(1.0, 0.5, 0.1, 0.45),
    DebugDraw3DNode.MeshType.MIXED,
  )
  _debug_draw.draw_flat_triangle(
    Vector3(11.0, 0.1, 16.0),
    Vector3(16.0, 0.1, 18.0),
    Vector3(13.0, 0.1, 22.0),
    Color.MAGENTA,
    DebugDraw3DNode.MeshType.WIREFRAME,
    DebugDraw3DNode.LineStyle.DASH,
  )


func _draw_volume_demos() -> void:
  _debug_draw.draw_box(
    Vector3(13.0, 3.0, -18.0),
    Vector3(5.0, 5.0, 5.0),
    Color(1.0, 0.9, 0.1, 0.35),
    DebugDraw3DNode.MeshType.SOLID,
  )
  _debug_draw.draw_sphere(
    Vector3(0.0, 5.0, -18.0),
    4.0,
    Color.GREEN,
    DebugDraw3DNode.MeshType.WIREFRAME,
  )
  _debug_draw.draw_cylinder(
    Vector3(-8.0, 3.0, -18.0),
    2.0,
    6.0,
    Color.ORANGE,
    DebugDraw3DNode.MeshType.MIXED,
  )
  _debug_draw.draw_capsule(
    Vector3(-16.0, 4.0, -18.0),
    1.5,
    7.0,
    Color.CORNFLOWER_BLUE,
    DebugDraw3DNode.MeshType.WIREFRAME,
  )
  _debug_draw.draw_cone(
    Vector3(22.0, 3.0, -18.0),
    2.5,
    6.0,
    Color.MAGENTA,
    DebugDraw3DNode.MeshType.WIREFRAME,
  )


func _draw_arrow_demos() -> void:
  var origin := Vector3(-22.0, 0.0, -6.0)
  _debug_draw.draw_arrow(
    origin,
    origin + Vector3.RIGHT * 6.0,
    Color.WHITE,
    DebugDraw3DNode.ArrowPointType.NONE,
  )
  _debug_draw.draw_arrow(
    origin + Vector3(0.0, 2.0, 0.0),
    origin + Vector3(6.0, 2.0, 0.0),
    Color.RED,
    DebugDraw3DNode.ArrowPointType.TRIANGLE,
  )
  _debug_draw.draw_arrow(
    origin,
    origin + Vector3.UP * 5.0,
    Color.GREEN,
    DebugDraw3DNode.ArrowPointType.PRISMATIC,
  )
  _debug_draw.draw_arrow(
    origin,
    origin + Vector3.BACK * 5.0,
    Color.BLUE,
    DebugDraw3DNode.ArrowPointType.CIRCLE,
    DebugDraw3DNode.LineStyle.DASH,
  )

  var arrow_curve_points := PackedVector3Array(
    [
      Vector3(-18.0, 0.5, -2.0),
      Vector3(-14.0, 4.0, 0.0),
      Vector3(-10.0, 1.0, 3.0),
      Vector3(-6.0, 4.0, 5.0),
    ],
  )
  _debug_draw.draw_arrow_curve(
    arrow_curve_points,
    Color.YELLOW,
    DebugDraw3DNode.CurveType.CATMULL_ROM,
    DebugDraw3DNode.ArrowPointType.CIRCLE,
  )
  _debug_draw.draw_3d_arrow(
    Vector3(3.0, 0.5, 12.0),
    Vector3(8.0, 4.0, 14.0),
    0.12,
    Color(1.0, 0.9, 0.2, 0.75),
    DebugDraw3DNode.ArrowPointType.PRISMATIC,
    true,
  )
  _debug_draw.draw_cylinder_arrow_curve(
    _offset_points(arrow_curve_points, Vector3(24.0, 0.0, 0.0)),
    0.1,
    Color(1.0, 0.45, 0.2, 0.85),
    DebugDraw3DNode.CurveType.BEZIER,
    DebugDraw3DNode.ArrowPointType.TRIANGLE,
    DebugDraw3DNode.MeshType.MIXED,
  )


func _setup_spatial_labels() -> void:
  _spatial_labels = Node3D.new()
  _spatial_labels.name = "SpatialLabels"
  add_child(_spatial_labels)
  _add_spatial_label(
    "ApiCoverageTitle",
    "API 覆盖样例\nDebugDraw3D 绘制能力总览",
    Vector3(0.0, 8.0, 0.0),
  )
  _add_spatial_label("LinesTitle", "线段 / 折线", Vector3(-16.0, 5.0, -20.0))
  _add_spatial_label(
    "LineStylesLabel",
    "draw_line\nLineStyle: DEFAULT / DASH / DOT\n别名: draw_line_3d",
    Vector3(-22.0, 4.0, -18.0),
  )
  _add_spatial_label(
    "PolylineLabel",
    "draw_polyline\nPackedVector3Array 多段折线\n别名: draw_polyline_3d",
    Vector3(-12.0, 6.5, -16.0),
  )
  _add_spatial_label("CurvesTitle", "曲线 / 箭头曲线", Vector3(-13.0, 7.0, 10.0))
  _add_spatial_label(
    "CurveTypesLabel",
    "draw_curve\nCurveType: BEZIER / ROUND_CORNER / CLOSED_ROUND_CORNER / CATMULL_ROM / LINES / HERMITE\n别名说明: draw_line_3d / draw_polyline_3d 仅说明不重复摆放",
    Vector3(-10.0, 8.0, 16.0),
  )
  _add_spatial_label("ArrowsTitle", "箭头 / 体积箭头", Vector3(-10.0, 7.0, -2.0))
  _add_spatial_label(
    "ArrowTypesLabel",
    "draw_arrow / draw_arrow_curve / draw_3d_arrow / draw_cylinder_arrow_curve\nArrowPointType: NONE / TRIANGLE / PRISMATIC / CIRCLE\n线框箭头与体积箭头对比",
    Vector3(-8.0, 7.0, 4.0),
  )
  _add_spatial_label("ShapesTitle", "平面与体积形状", Vector3(12.0, 7.0, -10.0))
  _add_spatial_label(
    "FlatShapesLabel",
    "draw_flat_circle / draw_flat_rect / draw_flat_triangle\n平面 normal / axis 参数控制朝向\nMeshType: MIXED / WIREFRAME",
    Vector3(16.0, 6.5, 14.0),
  )
  _add_spatial_label(
    "VolumeShapesLabel",
    "draw_box / draw_sphere / draw_cylinder / draw_capsule / draw_cone\n常用碰撞体调试体积\nMeshType: SOLID / WIREFRAME / MIXED",
    Vector3(2.0, 9.0, -18.0),
  )
  _add_spatial_label(
    "PipeShapesLabel",
    "draw_cylinder_line / draw_cylinder_polyline / draw_cylinder_curve\n粗线、粗折线、粗曲线\nMeshType: SOLID / WIREFRAME / MIXED",
    Vector3(4.0, 7.0, 0.0),
  )


func _offset_points(points: PackedVector3Array, offset: Vector3) -> PackedVector3Array:
  var result := PackedVector3Array()
  for point: Vector3 in points:
    result.append(point + offset)
  return result


func _add_spatial_label(label_name: String, text: String, label_position: Vector3) -> Label3D:
  var label := Label3D.new()
  label.name = label_name
  label.text = text
  label.position = label_position
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  label.fixed_size = true
  label.no_depth_test = true
  label.shaded = false
  label.double_sided = true
  label.font_size = LABEL_FONT_SIZE
  label.pixel_size = LABEL_PIXEL_SIZE
  label.modulate = Color(0.86, 0.94, 1.0, 1.0)
  label.outline_modulate = Color(0.02, 0.04, 0.06, 1.0)
  label.outline_size = 8
  label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  _spatial_labels.add_child(label)
  return label
