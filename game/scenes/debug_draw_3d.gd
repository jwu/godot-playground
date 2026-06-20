extends Node3D
## DebugDraw3D：3D 调试绘制演示，FreeCamera + 共享 DebugDraw3D 节点
##
## 相机操作由 res://entities/free_camera.tscn 提供。
## Esc 在 Freelook 中退出 Freelook，否则返回主菜单。

const DebugDraw3DNode := preload("res://shared/debug_draw_3d/debug_draw_3d.gd")
const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const GRID_HALF := 30

var _last_info_text := ""

@onready var _free_camera: FreeCamera = $FreeCamera
@onready var _info_label: Label = $UI/InfoLabel
@onready var _debug_draw: DebugDraw3DNode = $DebugDraw3D


func _ready() -> void:
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(roundi(DESIGN_WIDTH * dpi_scale), roundi(DESIGN_HEIGHT * dpi_scale))
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


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
  var text := _free_camera.get_info_text()
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


func _draw_curve_demos() -> void:
  var points := PackedVector3Array(
    [
      Vector3(-20.0, 0.0, 6.0),
      Vector3(-16.0, 4.0, 8.0),
      Vector3(-12.0, 1.0, 12.0),
      Vector3(-8.0, 5.0, 10.0),
    ],
  )
  var arrow_points := points.duplicate()
  arrow_points.append(Vector3(-4.0, 2.0, 12.0))
  _debug_draw.draw_curve(points, Color.CYAN, DebugDraw3DNode.CurveType.CATMULL_ROM)
  _debug_draw.draw_arrow_curve(
    arrow_points,
    Color.YELLOW,
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
    Color.YELLOW,
    DebugDraw3DNode.MeshType.WIREFRAME,
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
  _debug_draw.draw_3d_arrow(
    Vector3(3.0, 0.5, 12.0),
    Vector3(8.0, 4.0, 14.0),
    0.12,
    Color(1.0, 0.9, 0.2, 0.75),
    DebugDraw3DNode.ArrowPointType.PRISMATIC,
    true,
  )
