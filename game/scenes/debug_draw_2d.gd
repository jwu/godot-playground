extends Node2D
## DebugDraw2D：无限画布，支持缩放/平移，draw_line 参数效果展示
##
## 左键拖拽平移，滚轮/触控板纵向滑动缩放，Esc 返回主菜单。

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const GRID_SPACING := 10.0
const GRID_COLOR := Color(0.3, 0.3, 0.3, 0.5)
const GRID_COLOR_MAJOR := Color(0.4, 0.4, 0.4, 0.7)
const GRID_LOD_STEP := 10.0
const GRID_LOD_MIN_PIXELS := 4.0
const GRID_LINE_WIDTH_PIXELS := 1.0
const PAN_ZOOM_BASE := 1.05
const PAN_ZOOM_MAX_STEPS := 6.0
const MIN_ZOOM := 0.05
const MAX_ZOOM := 100.0
const LoggerEntity := preload("res://entities/logger.gd")

@onready var _logger: LoggerEntity = $UI/MouseLogPanel/Logger as LoggerEntity
@onready var _zoom_label: Label = $UI/ZoomLabel as Label

var _last_displayed_zoom := -1.0


func _ready() -> void:
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(DESIGN_WIDTH * dpi_scale, DESIGN_HEIGHT * dpi_scale)
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

  _update_zoom_info()


func _process(_delta: float) -> void:
  var zoom: float = $Camera2D.zoom.x
  if not is_equal_approx(zoom, _last_displayed_zoom):
    _update_zoom_info()


func _input(event: InputEvent) -> void:
  if event.is_action_pressed(&"ui_cancel"):
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
    return

  # 滚轮缩放
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_WHEEL_UP:
      _zoom_at(event.position, 1.1)
    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
      _zoom_at(event.position, 1.0 / 1.1)

  # 左键/中键拖拽平移
  if event is InputEventMouseMotion and (
      Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or
      Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
  ):
    $Camera2D.position -= event.relative / $Camera2D.zoom
    queue_redraw()

  # Mac 触控板双指纵向滑动 → 缩放
  if event is InputEventPanGesture:
    var zoom_steps := clampf(-event.delta.y, -PAN_ZOOM_MAX_STEPS, PAN_ZOOM_MAX_STEPS)
    if not is_zero_approx(zoom_steps):
      _zoom_at(get_viewport().get_mouse_position(), pow(PAN_ZOOM_BASE, zoom_steps))

  _log_mouse_event(event)


func _draw() -> void:
  _draw_grid()
  _draw_demos()


func _log_mouse_event(event: InputEvent) -> void:
  var message := _format_mouse_event(event)
  if message.is_empty():
    return

  _logger.log(message)


func _format_mouse_event(event: InputEvent) -> String:
  var ts := Time.get_ticks_msec() % 100000 # 取后 5 位毫秒
  var prefix := "[%05d] " % ts

  if event is InputEventMouseButton:
    var btn := ""
    match event.button_index:
      MOUSE_BUTTON_LEFT:
        btn = "LEFT"
      MOUSE_BUTTON_RIGHT:
        btn = "RIGHT"
      MOUSE_BUTTON_MIDDLE:
        btn = "MIDDLE"
      MOUSE_BUTTON_WHEEL_UP:
        btn = "WHEEL_UP"
      MOUSE_BUTTON_WHEEL_DOWN:
        btn = "WHEEL_DOWN"
      MOUSE_BUTTON_WHEEL_LEFT:
        btn = "WHEEL_LEFT"
      MOUSE_BUTTON_WHEEL_RIGHT:
        btn = "WHEEL_RIGHT"
      _:
        btn = "BTN_%d" % event.button_index
    var action := "press" if event.pressed else "release"
    return prefix + "MouseButton  %s %s  pos=(%.0f, %.0f)" % [btn, action, event.position.x, event.position.y]

  if event is InputEventMouseMotion:
    return prefix + "MouseMotion  pos=(%.0f, %.0f)  rel=(%.1f, %.1f)" % [event.position.x, event.position.y, event.relative.x, event.relative.y]

  if event is InputEventPanGesture:
    return prefix + "PanGesture  delta=(%.1f, %.1f)" % [event.delta.x, event.delta.y]

  return ""


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
  var cam := $Camera2D
  var pre_zoom: Vector2 = cam.zoom
  cam.zoom *= factor
  var z := clampf(cam.zoom.x, MIN_ZOOM, MAX_ZOOM)
  cam.zoom = Vector2(z, z)
  # 以鼠标位置为中心缩放
  cam.position += (screen_pos - get_viewport_rect().size / 2.0) * (1.0 / pre_zoom.x - 1.0 / cam.zoom.x)
  _update_zoom_info()
  queue_redraw()


func _update_zoom_info() -> void:
  var zoom: float = $Camera2D.zoom.x
  _last_displayed_zoom = zoom
  _zoom_label.text = "Zoom: %.3fx" % zoom


func _draw_grid() -> void:
  var cam: Camera2D = $Camera2D
  var zoom := cam.zoom.x
  var vp_size: Vector2 = get_viewport_rect().size / cam.zoom
  var cam_pos: Vector2 = cam.position

  var bounds := Rect2(
    cam_pos - vp_size / 2.0,
    vp_size
  )

  # 参考 The Machinery 的 grid renderer：根据屏幕像素密度自动切换 10 倍 LOD。
  # 缩小时合并为更大的格子，放大时细分为更小的格子，避免网格过密或过疏。
  var world_per_pixel := 1.0 / zoom
  var lod_level: float = log((world_per_pixel * GRID_LOD_MIN_PIXELS) / GRID_SPACING) / log(GRID_LOD_STEP) + 1.0
  var lod_power: float = floor(lod_level)
  var lod_fade: float = lod_level - lod_power

  var lod0_spacing: float = GRID_SPACING * pow(GRID_LOD_STEP, lod_power)
  var lod1_spacing: float = lod0_spacing * GRID_LOD_STEP
  var lod2_spacing: float = lod1_spacing * GRID_LOD_STEP
  var line_width: float = GRID_LINE_WIDTH_PIXELS / zoom

  var lod0_color := GRID_COLOR
  lod0_color.a *= 1.0 - lod_fade
  var lod1_color := GRID_COLOR_MAJOR.lerp(GRID_COLOR, lod_fade)

  _draw_grid_level(bounds, lod0_spacing, lod0_color, line_width)
  _draw_grid_level(bounds, lod1_spacing, lod1_color, line_width)
  _draw_grid_level(bounds, lod2_spacing, GRID_COLOR_MAJOR, line_width)


func _draw_grid_level(bounds: Rect2, spacing: float, color: Color, line_width: float) -> void:
  if spacing <= 0.0 or color.a <= 0.001:
    return

  var left := bounds.position.x
  var right := bounds.end.x
  var top := bounds.position.y
  var bottom := bounds.end.y

  var x: float = floor(left / spacing) * spacing
  while x <= right:
    draw_line(Vector2(x, top), Vector2(x, bottom), color, line_width, true)
    x += spacing

  var y: float = floor(top / spacing) * spacing
  while y <= bottom:
    draw_line(Vector2(left, y), Vector2(right, y), color, line_width, true)
    y += spacing


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
