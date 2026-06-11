extends Node2D
## DebugDraw2D：无限画布，支持缩放/平移，draw_line 参数效果展示
##
## 左键拖拽平移，滚轮缩放，Esc 返回主菜单。

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const GRID_SPACING := 40.0
const GRID_COLOR := Color(0.3, 0.3, 0.3, 0.5)
const GRID_COLOR_MAJOR := Color(0.4, 0.4, 0.4, 0.7)
const GRID_MAJOR_EVERY := 5


func _ready() -> void:
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(DESIGN_WIDTH * dpi_scale, DESIGN_HEIGHT * dpi_scale)
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _input(event: InputEvent) -> void:
  if event.is_action_pressed(&"ui_cancel"):
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

  # 滚轮缩放
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP:
      _zoom_at(event.position, 1.1)
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
      _zoom_at(event.position, 1.0 / 1.1)

  # Mac 触控板捏合 → 缩放（factor 值很小，需放大）
  if event is InputEventMagnifyGesture:
    if event.factor > 0.0:
      _zoom_at(get_viewport().get_mouse_position(), 1.05)
    else:
      _zoom_at(get_viewport().get_mouse_position(), 1.0 / 1.05)

  # 左键/中键拖拽平移
  if event is InputEventMouseMotion and (
      Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or
      Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
  ):
    $Camera2D.position -= event.relative / $Camera2D.zoom

  # Mac 触控板双指滑动 → 平移
  if event is InputEventPanGesture:
    $Camera2D.position -= event.delta / $Camera2D.zoom


func _draw() -> void:
  _draw_grid()
  _draw_demos()


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
  var cam := $Camera2D
  var pre_zoom: Vector2 = cam.zoom
  cam.zoom *= factor
  var z := clampf(cam.zoom.x, 0.1, 10.0)
  cam.zoom = Vector2(z, z)
  # 以鼠标位置为中心缩放
  cam.position += (screen_pos - get_viewport_rect().size / 2.0) * (1.0 / pre_zoom.x - 1.0 / cam.zoom.x)


func _draw_grid() -> void:
  var cam: Camera2D = $Camera2D
  var vp_size: Vector2 = get_viewport_rect().size / cam.zoom
  var cam_pos: Vector2 = cam.position

  var left: float = cam_pos.x - vp_size.x / 2.0
  var right: float = cam_pos.x + vp_size.x / 2.0
  var top: float = cam_pos.y - vp_size.y / 2.0
  var bottom: float = cam_pos.y + vp_size.y / 2.0

  # 垂直线
  var x: float = floor(left / GRID_SPACING) * GRID_SPACING
  while x <= right:
    var is_major: bool = is_equal_approx(fmod(abs(x), GRID_SPACING * GRID_MAJOR_EVERY), 0.0)
    draw_line(Vector2(x, top), Vector2(x, bottom), GRID_COLOR_MAJOR if is_major else GRID_COLOR, -1.0)
    x += GRID_SPACING

  # 水平线
  var y: float = floor(top / GRID_SPACING) * GRID_SPACING
  while y <= bottom:
    var is_major: bool = is_equal_approx(fmod(abs(y), GRID_SPACING * GRID_MAJOR_EVERY), 0.0)
    draw_line(Vector2(left, y), Vector2(right, y), GRID_COLOR_MAJOR if is_major else GRID_COLOR, -1.0)
    y += GRID_SPACING


func _draw_demos() -> void:
  var o := Vector2(-300, -160)
  var gap := 60.0
  var font := ThemeDB.fallback_font
  var len := 200.0
  var label_offset := Vector2(len + 8, -6)

  # 1. width=-1
  draw_line(o, o + Vector2(len, 0), Color.WHITE, -1.0)
  draw_string(font, o + label_offset, "width=-1 (1px)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 2. width=1, no aa
  o.y += gap
  draw_line(o, o + Vector2(len, 0), Color.RED, 1.0)
  draw_string(font, o + label_offset, "width=1, aa=false", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 3. width=1, aa
  o.y += gap
  draw_line(o, o + Vector2(len, 0), Color.GREEN, 1.0, true)
  draw_string(font, o + label_offset, "width=1, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 4. width=3
  o.y += gap
  draw_line(o, o + Vector2(len, 0), Color.BLUE, 3.0)
  draw_string(font, o + label_offset, "width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 5. width=6, aa
  o.y += gap
  draw_line(o, o + Vector2(len, 0), Color.YELLOW, 6.0, true)
  draw_string(font, o + label_offset, "width=6, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 6. width=12, aa
  o.y += gap
  draw_line(o, o + Vector2(len, 0), Color.MAGENTA, 12.0, true)
  draw_string(font, o + label_offset, "width=12, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 7. diagonal
  o.y += gap
  draw_line(o, o + Vector2(len, -40), Color.CYAN, 4.0, true)
  draw_string(font, o + label_offset - Vector2(0, 20), "diagonal, width=4", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
