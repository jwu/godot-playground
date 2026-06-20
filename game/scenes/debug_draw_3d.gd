extends Node3D
## DebugDraw3D：3D 调试绘制演示，FreeCamera + 共享 DebugDraw3D 节点
##
## 相机操作由 res://entities/free_camera.tscn 提供。
## Esc 在 Freelook 中退出 Freelook，否则返回主菜单。

const DebugDraw3DNode := preload("res://shared/debug_draw_3d/debug_draw_3d.gd")
const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const GRID_HALF := 30
const LAYER_LINES := 1
const LAYER_SHAPES := 2
const LAYER_BEHAVIOR := 4
const ALL_DEMO_LAYERS := LAYER_LINES | LAYER_SHAPES | LAYER_BEHAVIOR
const LABEL_FONT_SIZE := 36
const LABEL_PIXEL_SIZE := 0.02
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
  _debug_draw.visible_layers = ALL_DEMO_LAYERS
  _setup_spatial_labels()
  _update_info_label()


func _process(_delta: float) -> void:
  _update_info_label()
  _draw_demos()


func _input(event: InputEvent) -> void:
  if _handle_layer_input(event):
    return

  if event.is_action_pressed(&"ui_cancel"):
    if _free_camera.is_freelook_active():
      _free_camera.set_freelook_active(false)
    else:
      get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _update_info_label() -> void:
  var text := INFO_PREFIX + _layer_info_text() + "\n" + _free_camera.get_info_text()
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
  _draw_behavior_demos()


func _draw_axes() -> void:
  var axis_len := float(GRID_HALF) + 2.0
  _debug_draw.draw_line(
    Vector3(-axis_len, 0.0, 0.0),
    Vector3(axis_len, 0.0, 0.0),
    Color.RED,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_BEHAVIOR,
  )
  _debug_draw.draw_line(
    Vector3(0.0, -axis_len, 0.0),
    Vector3(0.0, axis_len, 0.0),
    Color.GREEN,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_BEHAVIOR,
  )
  _debug_draw.draw_line(
    Vector3(0.0, 0.0, -axis_len),
    Vector3(0.0, 0.0, axis_len),
    Color.BLUE,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_BEHAVIOR,
  )


func _draw_line_demos() -> void:
  var origin := Vector3(-20.0, 0.0, -20.0)
  _debug_draw.draw_line(
    origin,
    origin + Vector3(8.0, 0.0, 0.0),
    Color.WHITE,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_LINES,
  )
  _debug_draw.draw_line(
    origin,
    origin + Vector3(0.0, 6.0, 0.0),
    Color.RED,
    DebugDraw3DNode.LineStyle.DASH,
    false,
    LAYER_LINES,
  )
  _debug_draw.draw_line(
    origin,
    origin + Vector3(0.0, 0.0, 8.0),
    Color.GREEN,
    DebugDraw3DNode.LineStyle.DOT,
    false,
    LAYER_LINES,
  )
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
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_LINES,
  )
  _debug_draw.draw_cylinder_line(
    origin + Vector3(10.0, 0.0, 0.0),
    origin + Vector3(10.0, 5.0, 5.0),
    0.12,
    Color.ORANGE,
    DebugDraw3DNode.MeshType.MIXED,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
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
    DebugDraw3DNode.MeshType.WIREFRAME,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
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
      DebugDraw3DNode.LineStyle.DEFAULT,
      false,
      LAYER_LINES,
    )

  var arrow_points := _offset_points(base_points, Vector3(0.0, 0.0, 14.0))
  arrow_points.append(Vector3(-4.0, 2.0, 26.0))
  _debug_draw.draw_arrow_curve(
    arrow_points,
    Color.YELLOW,
    DebugDraw3DNode.CurveType.CATMULL_ROM,
    DebugDraw3DNode.ArrowPointType.PRISMATIC,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_LINES,
  )
  _debug_draw.draw_cylinder_curve(
    _offset_points(base_points, Vector3(10.0, 0.0, 14.0)),
    0.08,
    Color(0.4, 1.0, 0.6, 0.8),
    DebugDraw3DNode.CurveType.BEZIER,
    DebugDraw3DNode.MeshType.MIXED,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
  )
  _debug_draw.draw_cylinder_arrow_curve(
    arrow_points,
    0.08,
    Color(1.0, 0.6, 0.2, 0.85),
    DebugDraw3DNode.CurveType.CATMULL_ROM,
    DebugDraw3DNode.ArrowPointType.PRISMATIC,
    DebugDraw3DNode.MeshType.SOLID,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
  )


func _draw_flat_shape_demos() -> void:
  _debug_draw.draw_flat_circle(
    Vector3(10.0, 0.05, 10.0),
    3.0,
    Vector3.UP,
    Color(0.2, 0.8, 1.0, 0.35),
    DebugDraw3DNode.MeshType.MIXED,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
  )
  _debug_draw.draw_flat_rect(
    Vector3(18.0, 2.0, 8.0),
    Vector2(5.0, 3.0),
    Vector3.RIGHT,
    Vector3.UP,
    Color(1.0, 0.5, 0.1, 0.45),
    DebugDraw3DNode.MeshType.MIXED,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
  )
  _debug_draw.draw_flat_triangle(
    Vector3(11.0, 0.1, 16.0),
    Vector3(16.0, 0.1, 18.0),
    Vector3(13.0, 0.1, 22.0),
    Color.MAGENTA,
    DebugDraw3DNode.MeshType.WIREFRAME,
    DebugDraw3DNode.LineStyle.DASH,
    false,
    LAYER_SHAPES,
  )


func _draw_volume_demos() -> void:
  _debug_draw.draw_box(
    Vector3(13.0, 3.0, -18.0),
    Vector3(5.0, 5.0, 5.0),
    Color(1.0, 0.9, 0.1, 0.35),
    DebugDraw3DNode.MeshType.SOLID,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
  )
  _debug_draw.draw_sphere(
    Vector3(0.0, 5.0, -18.0),
    4.0,
    Color.GREEN,
    DebugDraw3DNode.MeshType.WIREFRAME,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
  )
  _debug_draw.draw_cylinder(
    Vector3(-8.0, 3.0, -18.0),
    2.0,
    6.0,
    Color.ORANGE,
    DebugDraw3DNode.MeshType.MIXED,
    Vector3.UP,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
  )
  _debug_draw.draw_capsule(
    Vector3(-16.0, 4.0, -18.0),
    1.5,
    7.0,
    Color.CORNFLOWER_BLUE,
    DebugDraw3DNode.MeshType.WIREFRAME,
    Vector3.UP,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
  )
  _debug_draw.draw_cone(
    Vector3(22.0, 3.0, -18.0),
    2.5,
    6.0,
    Color.MAGENTA,
    DebugDraw3DNode.MeshType.WIREFRAME,
    Vector3.UP,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
  )


func _draw_arrow_demos() -> void:
  var origin := Vector3(-22.0, 0.0, -6.0)
  _debug_draw.draw_arrow(
    origin,
    origin + Vector3.RIGHT * 6.0,
    Color.WHITE,
    DebugDraw3DNode.ArrowPointType.NONE,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_LINES,
  )
  _debug_draw.draw_arrow(
    origin + Vector3(0.0, 2.0, 0.0),
    origin + Vector3(6.0, 2.0, 0.0),
    Color.RED,
    DebugDraw3DNode.ArrowPointType.TRIANGLE,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_LINES,
  )
  _debug_draw.draw_arrow(
    origin,
    origin + Vector3.UP * 5.0,
    Color.GREEN,
    DebugDraw3DNode.ArrowPointType.PRISMATIC,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_LINES,
  )
  _debug_draw.draw_arrow(
    origin,
    origin + Vector3.BACK * 5.0,
    Color.BLUE,
    DebugDraw3DNode.ArrowPointType.CIRCLE,
    DebugDraw3DNode.LineStyle.DASH,
    false,
    LAYER_LINES,
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
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_LINES,
  )
  _debug_draw.draw_3d_arrow(
    Vector3(3.0, 0.5, 12.0),
    Vector3(8.0, 4.0, 14.0),
    0.12,
    Color(1.0, 0.9, 0.2, 0.75),
    DebugDraw3DNode.ArrowPointType.PRISMATIC,
    true,
    LAYER_LINES,
  )
  _debug_draw.draw_cylinder_arrow_curve(
    _offset_points(arrow_curve_points, Vector3(24.0, 0.0, 0.0)),
    0.1,
    Color(1.0, 0.45, 0.2, 0.85),
    DebugDraw3DNode.CurveType.BEZIER,
    DebugDraw3DNode.ArrowPointType.TRIANGLE,
    DebugDraw3DNode.MeshType.MIXED,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_SHAPES,
  )


func _setup_spatial_labels() -> void:
  _spatial_labels = Node3D.new()
  _spatial_labels.name = "SpatialLabels"
  add_child(_spatial_labels)
  _add_spatial_label(
    "ApiCoverageTitle",
    "API 覆盖样例\nDebugDraw3D 绘制能力总览",
    Vector3(-5.0, 9.0, 2.0),
    0.0,
  )
  _add_spatial_label("LinesTitle", "线段 / 折线", Vector3(-22.0, 4.0, -22.0), 20.0)
  _add_spatial_label("CurvesTitle", "曲线", Vector3(-22.0, 7.0, 14.0), 20.0)
  _add_spatial_label("ArrowsTitle", "箭头 / 体积箭头", Vector3(-22.0, 6.0, -4.0), 20.0)
  _add_spatial_label("ShapesTitle", "平面 / 体积 / 管线形状", Vector3(12.0, 8.0, -22.0), -20.0)
  _add_spatial_label("BehaviorTitle", "渲染行为 / Layer", Vector3(18.0, 7.0, 6.0), -35.0)


func _draw_behavior_demos() -> void:
  var occluder_center := Vector3(20.0, 2.0, 0.0)
  _debug_draw.draw_box(
    occluder_center,
    Vector3(3.0, 4.0, 3.0),
    Color(0.25, 0.25, 0.28, 0.65),
    DebugDraw3DNode.MeshType.SOLID,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_BEHAVIOR,
  )
  _debug_draw.draw_line(
    occluder_center + Vector3(-4.0, 0.0, 0.0),
    occluder_center + Vector3(4.0, 0.0, 0.0),
    Color.RED,
    DebugDraw3DNode.LineStyle.DEFAULT,
    false,
    LAYER_BEHAVIOR,
  )
  _debug_draw.draw_line(
    occluder_center + Vector3(-4.0, 1.0, 1.0),
    occluder_center + Vector3(4.0, 1.0, 1.0),
    Color.LIME_GREEN,
    DebugDraw3DNode.LineStyle.DEFAULT,
    true,
    LAYER_BEHAVIOR,
  )


func _handle_layer_input(event: InputEvent) -> bool:
  if not event is InputEventKey:
    return false

  var key_event := event as InputEventKey
  if not key_event.pressed or key_event.echo:
    return false

  match key_event.keycode:
    KEY_1:
      _toggle_layer(LAYER_LINES)
      return true
    KEY_2:
      _toggle_layer(LAYER_SHAPES)
      return true
    KEY_3:
      _toggle_layer(LAYER_BEHAVIOR)
      return true
  return false


func _toggle_layer(layer: int) -> void:
  _debug_draw.set_layer_enabled(layer, (_debug_draw.visible_layers & layer) == 0)
  _last_info_text = ""
  _update_info_label()


func _layer_info_text() -> String:
  return "Layer: 1=%s 2=%s 3=%s" % [
    _layer_state_text(LAYER_LINES),
    _layer_state_text(LAYER_SHAPES),
    _layer_state_text(LAYER_BEHAVIOR),
  ]


func _layer_state_text(layer: int) -> String:
  return "ON" if (_debug_draw.visible_layers & layer) != 0 else "OFF"


func _offset_points(points: PackedVector3Array, offset: Vector3) -> PackedVector3Array:
  var result := PackedVector3Array()
  for point: Vector3 in points:
    result.append(point + offset)
  return result


func _add_spatial_label(
    label_name: String,
    text: String,
    label_position: Vector3,
    yaw_degrees: float,
) -> Label3D:
  var label := Label3D.new()
  label.name = label_name
  label.text = text
  label.position = label_position
  label.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
  label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
  label.fixed_size = false
  label.no_depth_test = false
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
