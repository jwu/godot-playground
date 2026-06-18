extends Node3D
## DebugDraw3D：3D 调试绘制演示，轨道相机 + ImmediateMesh 动态绘制
##
## 右键拖拽旋转，滚轮/触控板缩放，中键拖拽平移，Esc 返回主菜单。
## 展示：坐标轴、XZ 网格(LOD)、3D 线段、线框图元、点标记、方向射线。

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const ORBIT_SENSITIVITY := 0.004
const PAN_FACTOR := 0.005
const ZOOM_FACTOR := 1.08
const PAN_ZOOM_MAX_STEPS := 6.0
const MIN_DISTANCE := 0.5
const MAX_DISTANCE := 300.0
const DEFAULT_DISTANCE := 16.0
const GRID_HALF := 30

var _yaw := -PI * 0.25
var _pitch := PI * 0.28
var _distance := DEFAULT_DISTANCE
var _target := Vector3.ZERO
var _last_info_text := ""

@onready var _camera: Camera3D = $Camera3D
@onready var _info_label: Label = $UI/InfoLabel
@onready var _mesh_instance: MeshInstance3D = $DrawMesh


func _ready() -> void:
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(roundi(DESIGN_WIDTH * dpi_scale), roundi(DESIGN_HEIGHT * dpi_scale))
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

  _mesh_instance.mesh = ImmediateMesh.new()
  _update_camera()


func _process(_delta: float) -> void:
  _update_info_label()
  _redraw()


func _input(event: InputEvent) -> void:
  if event.is_action_pressed(&"ui_cancel"):
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
    return

  # 滚轮缩放
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP:
      _distance = clampf(_distance / ZOOM_FACTOR, MIN_DISTANCE, MAX_DISTANCE)
      _update_camera()
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
      _distance = clampf(_distance * ZOOM_FACTOR, MIN_DISTANCE, MAX_DISTANCE)
      _update_camera()

  # 右键拖拽旋转
  if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
    _yaw -= event.relative.x * ORBIT_SENSITIVITY
    _pitch = clampf(_pitch - event.relative.y * ORBIT_SENSITIVITY, 0.05, PI - 0.05)
    _update_camera()

  # 中键拖拽平移
  if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
    var right := _camera.global_transform.basis.x
    var up := _camera.global_transform.basis.y
    _target -= (right * event.relative.x + up * event.relative.y) * PAN_FACTOR * _distance * 0.01
    _update_camera()

  # Mac 触控板双指纵向滑动 → 缩放
  if event is InputEventPanGesture:
    var steps := clampf(event.delta.y, -PAN_ZOOM_MAX_STEPS, PAN_ZOOM_MAX_STEPS)
    if not is_zero_approx(steps):
      _distance = clampf(_distance * pow(ZOOM_FACTOR, steps), MIN_DISTANCE, MAX_DISTANCE)
      _update_camera()


func _update_camera() -> void:
  _camera.position = _target + Vector3(
    _distance * cos(_pitch) * cos(_yaw),
    _distance * sin(_pitch),
    _distance * cos(_pitch) * sin(_yaw),
  )
  _camera.look_at(_target)


func _update_info_label() -> void:
  var text := "Camera  Dist: %.1f  Yaw: %.0f°  Pitch: %.0f°  Target: (%.1f, %.1f, %.1f)" % [
    _distance,
    rad_to_deg(_yaw),
    rad_to_deg(_pitch),
    _target.x,
    _target.y,
    _target.z,
  ]
  if text != _last_info_text:
    _info_label.text = text
    _last_info_text = text


func _redraw() -> void:
  var im := _mesh_instance.mesh as ImmediateMesh
  im.clear_surfaces()

  # 绘制顺序：EndlessGrid3D entity 负责 grid，这里只画调试线框元素。
  _draw_axes(im)
  _draw_line_demos(im)
  _draw_wireframe_demos(im)
  _draw_point_demos(im)
  _draw_ray_demos(im)


# ============================================================
# 坐标轴（RGB）
# ============================================================
func _draw_axes(im: ImmediateMesh) -> void:
  var axis_len := float(GRID_HALF) + 2.0

  im.surface_begin(Mesh.PRIMITIVE_LINES)

  # X 轴 — 红色
  im.surface_set_color(Color.RED)
  im.surface_add_vertex(Vector3(-axis_len, 0, 0))
  im.surface_add_vertex(Vector3(axis_len, 0, 0))

  # Y 轴 — 绿色
  im.surface_set_color(Color.GREEN)
  im.surface_add_vertex(Vector3(0, -axis_len, 0))
  im.surface_add_vertex(Vector3(0, axis_len, 0))

  # Z 轴 — 蓝色
  im.surface_set_color(Color.BLUE)
  im.surface_add_vertex(Vector3(0, 0, -axis_len))
  im.surface_add_vertex(Vector3(0, 0, axis_len))

  im.surface_end()


# ============================================================
# 3D 线段演示
# ============================================================
func _draw_line_demos(im: ImmediateMesh) -> void:
  ## 展示空间中不同方向、不同颜色的线段
  var o := Vector3(-20, 0, -20)

  im.surface_begin(Mesh.PRIMITIVE_LINES)

  # 水平 X
  im.surface_set_color(Color.WHITE)
  im.surface_add_vertex(o)
  im.surface_add_vertex(o + Vector3(8, 0, 0))
  # 竖直 Y
  im.surface_set_color(Color.RED)
  im.surface_add_vertex(o)
  im.surface_add_vertex(o + Vector3(0, 6, 0))
  # 深度 Z
  im.surface_set_color(Color.GREEN)
  im.surface_add_vertex(o)
  im.surface_add_vertex(o + Vector3(0, 0, 8))
  # 斜向
  im.surface_set_color(Color.CYAN)
  im.surface_add_vertex(o)
  im.surface_add_vertex(o + Vector3(5, 3, 4))
  # 交叉线
  im.surface_set_color(Color.YELLOW)
  im.surface_add_vertex(o + Vector3(8, 0, 8))
  im.surface_add_vertex(o + Vector3(0, 6, 0))
  # 竖线
  im.surface_set_color(Color.MAGENTA)
  im.surface_add_vertex(o + Vector3(8, 0, 0))
  im.surface_add_vertex(o + Vector3(8, 6, 0))
  # 平行 Z
  im.surface_set_color(Color.ORANGE)
  im.surface_add_vertex(o + Vector3(0, 3, 0))
  im.surface_add_vertex(o + Vector3(0, 3, 8))
  # 跳跃线
  im.surface_set_color(Color.DEEP_SKY_BLUE)
  im.surface_add_vertex(o + Vector3(0, 0, 8))
  im.surface_add_vertex(o + Vector3(8, 6, 0))

  im.surface_end()


# ============================================================
# 线框图元演示
# ============================================================
func _draw_wireframe_demos(im: ImmediateMesh) -> void:
  # 线框立方体
  _draw_wireframe_cube(im, Vector3(13, 3, -18), 5.0, Color.YELLOW)

  # 线框球体（用三个正交圆表示）
  var sc := Vector3(0, 5, -18)
  var sr := 4.0
  _draw_circle_3d(im, sc, sr, Vector3.RIGHT, Vector3.FORWARD, Color.GREEN) # XZ 平面
  _draw_circle_3d(im, sc, sr, Vector3.RIGHT, Vector3.UP, Color.GREEN) # XY 平面
  _draw_circle_3d(im, sc, sr, Vector3.UP, Vector3.FORWARD, Color.GREEN) # YZ 平面

  # 线框金字塔
  _draw_wireframe_pyramid(im, Vector3(-10, 9, -18), 6.0, Color.MAGENTA)


func _draw_wireframe_cube(im: ImmediateMesh, center: Vector3, size: float, color: Color) -> void:
  var h := size * 0.5
  var o := center

  im.surface_begin(Mesh.PRIMITIVE_LINES)
  im.surface_set_color(color)

  var corners := [
    o + Vector3(-h, -h, -h),
    o + Vector3(h, -h, -h),
    o + Vector3(h, -h, h),
    o + Vector3(-h, -h, h),
    o + Vector3(-h, h, -h),
    o + Vector3(h, h, -h),
    o + Vector3(h, h, h),
    o + Vector3(-h, h, h),
  ]
  var c := corners # 简写

  # 底面
  im.surface_add_vertex(c[0])
  im.surface_add_vertex(c[1])
  im.surface_add_vertex(c[1])
  im.surface_add_vertex(c[2])
  im.surface_add_vertex(c[2])
  im.surface_add_vertex(c[3])
  im.surface_add_vertex(c[3])
  im.surface_add_vertex(c[0])
  # 顶面
  im.surface_add_vertex(c[4])
  im.surface_add_vertex(c[5])
  im.surface_add_vertex(c[5])
  im.surface_add_vertex(c[6])
  im.surface_add_vertex(c[6])
  im.surface_add_vertex(c[7])
  im.surface_add_vertex(c[7])
  im.surface_add_vertex(c[4])
  # 竖边
  im.surface_add_vertex(c[0])
  im.surface_add_vertex(c[4])
  im.surface_add_vertex(c[1])
  im.surface_add_vertex(c[5])
  im.surface_add_vertex(c[2])
  im.surface_add_vertex(c[6])
  im.surface_add_vertex(c[3])
  im.surface_add_vertex(c[7])

  im.surface_end()


func _draw_circle_3d(im: ImmediateMesh, center: Vector3, radius: float, axis_u: Vector3, axis_v: Vector3, color: Color) -> void:
  ## 在 3D 空间中绘制圆（由 axis_u 和 axis_v 张成的平面内）
  var segments := 64
  im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
  im.surface_set_color(color)
  for i in range(segments + 1):
    var angle := TAU * float(i) / float(segments)
    im.surface_add_vertex(center + axis_u * radius * cos(angle) + axis_v * radius * sin(angle))
  im.surface_end()


func _draw_wireframe_pyramid(im: ImmediateMesh, apex: Vector3, base_size: float, color: Color) -> void:
  var h := base_size * 0.5
  var b := [
    apex + Vector3(-h, -base_size, -h),
    apex + Vector3(h, -base_size, -h),
    apex + Vector3(h, -base_size, h),
    apex + Vector3(-h, -base_size, h),
  ]

  im.surface_begin(Mesh.PRIMITIVE_LINES)
  im.surface_set_color(color)
  # 底面
  im.surface_add_vertex(b[0])
  im.surface_add_vertex(b[1])
  im.surface_add_vertex(b[1])
  im.surface_add_vertex(b[2])
  im.surface_add_vertex(b[2])
  im.surface_add_vertex(b[3])
  im.surface_add_vertex(b[3])
  im.surface_add_vertex(b[0])
  # 顶点连线
  im.surface_add_vertex(b[0])
  im.surface_add_vertex(apex)
  im.surface_add_vertex(b[1])
  im.surface_add_vertex(apex)
  im.surface_add_vertex(b[2])
  im.surface_add_vertex(apex)
  im.surface_add_vertex(b[3])
  im.surface_add_vertex(apex)
  im.surface_end()


# ============================================================
# 点标记演示
# ============================================================
func _draw_point_demos(im: ImmediateMesh) -> void:
  ## 用小十字标记 3D 空间中的点
  var points := PackedVector3Array(
    [
      Vector3(18, 0.5, -14),
      Vector3(20, 2.5, -10),
      Vector3(22, 1.5, -6),
      Vector3(18, 4.0, -2),
    ],
  )
  var colors := PackedColorArray([Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW])
  var cross := 0.5

  im.surface_begin(Mesh.PRIMITIVE_LINES)
  for i in points.size():
    var p: Vector3 = points[i]
    var col: Color = colors[i]
    im.surface_set_color(col)
    im.surface_add_vertex(p + Vector3(-cross, 0, 0))
    im.surface_add_vertex(p + Vector3(cross, 0, 0))
    im.surface_add_vertex(p + Vector3(0, -cross, 0))
    im.surface_add_vertex(p + Vector3(0, cross, 0))
    im.surface_add_vertex(p + Vector3(0, 0, -cross))
    im.surface_add_vertex(p + Vector3(0, 0, cross))
  im.surface_end()


# ============================================================
# 方向射线演示
# ============================================================
func _draw_ray_demos(im: ImmediateMesh) -> void:
  ## 展示从原点发出的带箭头标记的方向射线
  var o := Vector3(-22, 0, -6)

  var dirs := PackedVector3Array([Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(0.7, 0.5, 0.5).normalized()])
  var cols := PackedColorArray([Color.RED, Color.GREEN, Color.BLUE, Color.ORANGE])
  var lengths := PackedFloat32Array([6.0, 5.0, 5.0, 5.0])
  var arrow_size := 0.35

  im.surface_begin(Mesh.PRIMITIVE_LINES)
  for i in dirs.size():
    var d: Vector3 = dirs[i]
    var col: Color = cols[i]
    var l: float = lengths[i]
    var end_pt: Vector3 = o + d * l

    # 射线本体
    im.surface_set_color(col)
    im.surface_add_vertex(o)
    im.surface_add_vertex(end_pt)

    # 箭头末端十字
    im.surface_set_color(col.lightened(0.3))
    im.surface_add_vertex(end_pt + Vector3(-arrow_size, 0, 0))
    im.surface_add_vertex(end_pt + Vector3(arrow_size, 0, 0))
    im.surface_add_vertex(end_pt + Vector3(0, -arrow_size, 0))
    im.surface_add_vertex(end_pt + Vector3(0, arrow_size, 0))
    im.surface_add_vertex(end_pt + Vector3(0, 0, -arrow_size))
    im.surface_add_vertex(end_pt + Vector3(0, 0, arrow_size))
  im.surface_end()
