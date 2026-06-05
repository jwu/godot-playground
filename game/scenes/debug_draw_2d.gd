extends ColorRect
## DebugDraw2D：展示 CanvasItem 各种 draw_xxx 方法，并支持鼠标自由画线。
##
## 左侧为预设 Demo 形状，中间区域可以鼠标自由画线，
## 顶部工具栏可切换颜色、线宽、清除画布。

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720

# 鼠标画线相关
var _drawing := false
var _lines: Array[Dictionary] = [] # [{points: PackedVector2Array, color: Color, width: float}]
var _current_line_points := PackedVector2Array()
var _current_color := Color.RED
var _current_width := 2.0
# 预设 demo 形状开关
var _show_demos := true


# --------------------------------------------------
# 生命周期
# --------------------------------------------------
func _ready() -> void:
  # Retina DPI 适配
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(DESIGN_WIDTH * dpi_scale, DESIGN_HEIGHT * dpi_scale)
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

  $Toolbar/BackBtn.pressed.connect(_on_back_pressed)
  $Toolbar/ColorPicker.item_selected.connect(_on_color_selected)
  $Toolbar/WidthSlider.value_changed.connect(_on_width_changed)
  $Toolbar/ClearBtn.pressed.connect(_on_clear_pressed)
  $Toolbar/DemoToggle.toggled.connect(_on_demo_toggled)


# --------------------------------------------------
# 输入处理
# --------------------------------------------------
func _gui_input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_LEFT:
      if event.pressed:
        _drawing = true
        _current_line_points.clear()
        _current_line_points.append(event.position)
      else:
        if _drawing and _current_line_points.size() >= 2:
          _lines.append(
            {
              points = _current_line_points,
              color = _current_color,
              width = _current_width,
            },
          )
          queue_redraw()
        _drawing = false

  elif event is InputEventMouseMotion and _drawing:
    _current_line_points.append(event.position)
    queue_redraw()


# --------------------------------------------------
# 绘制
# --------------------------------------------------
func _draw() -> void:
  _draw_grid()

  for line in _lines:
    _draw_line_segment(line.points, line.color, line.width)

  if _drawing and _current_line_points.size() >= 2:
    _draw_line_segment(_current_line_points, _current_color, _current_width)

  if _show_demos:
    _draw_demos()


# --------------------------------------------------
# 公开访问器（供测试使用）
# --------------------------------------------------
func get_current_color() -> Color:
  return _current_color


func get_line_width() -> float:
  return _current_width


func get_line_count() -> int:
  return _lines.size()


func is_demo_visible() -> bool:
  return _show_demos


# --------------------------------------------------
# 信号回调
# --------------------------------------------------
func _on_back_pressed() -> void:
  get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_color_selected(idx: int) -> void:
  var colors := [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.WHITE, Color.MAGENTA, Color.CYAN]
  if idx >= 0 and idx < colors.size():
    _current_color = colors[idx]


func _on_width_changed(value: float) -> void:
  _current_width = value
  $Toolbar/WidthLabel.text = "宽:%.0f" % value


func _on_clear_pressed() -> void:
  _lines.clear()
  queue_redraw()


func _on_demo_toggled(pressed: bool) -> void:
  _show_demos = pressed
  queue_redraw()


# --------------------------------------------------
# 内部方法
# --------------------------------------------------
func _draw_grid() -> void:
  var grid_spacing := 40.0
  var grid_color := Color(0.25, 0.25, 0.25, 0.4)
  var s := get_viewport().get_visible_rect().size

  var x := 0.0
  while x < s.x:
    draw_line(Vector2(x, 0), Vector2(x, s.y), grid_color, 1.0)
    x += grid_spacing

  var y := 0.0
  while y < s.y:
    draw_line(Vector2(0, y), Vector2(s.x, y), grid_color, 1.0)
    y += grid_spacing


func _draw_line_segment(points: PackedVector2Array, color: Color, width: float) -> void:
  draw_polyline(points, color, width, true)


func _draw_demos() -> void:
  var o := Vector2(60, 420)
  var gap := 85.0
  var font := ThemeDB.fallback_font

  # 1. draw_line
  draw_line(o, o + Vector2(80, 0), Color.RED, 3.0)
  draw_string(font, o + Vector2(0, 14), "draw_line", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 2. draw_dashed_line
  o.y += gap
  draw_dashed_line(o, o + Vector2(80, 0), Color.YELLOW, 2.0, 6.0)
  draw_string(font, o + Vector2(0, 14), "draw_dashed_line", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 3. draw_rect 空心
  o.y += gap
  draw_rect(Rect2(o, Vector2(60, 30)), Color.GREEN, false, 2.0)
  draw_string(font, o + Vector2(0, 34), "draw_rect(空心)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 4. draw_rect 实心
  o.y += gap
  draw_rect(Rect2(o, Vector2(60, 30)), Color(0, 1, 0, 0.25), true)
  draw_string(font, o + Vector2(0, 34), "draw_rect(实心)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 5. draw_circle
  o.y += gap
  draw_circle(o + Vector2(30, 15), 20, Color.BLUE, false, 2.0)
  draw_string(font, o + Vector2(0, 38), "draw_circle", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 6. draw_arc
  o.y += gap
  draw_arc(o + Vector2(30, 15), 20, 0, PI, 24, Color.MAGENTA, 2.0)
  draw_string(font, o + Vector2(0, 38), "draw_arc", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 7. draw_polygon
  o.y += gap
  var tri := PackedVector2Array([o, o + Vector2(60, 0), o + Vector2(30, 30)])
  draw_polygon(tri, PackedColorArray([Color.RED, Color.GREEN, Color.BLUE]))
  draw_string(font, o + Vector2(0, 34), "draw_polygon", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 8. draw_multiline
  o.y += gap
  var ml := PackedVector2Array([o, o + Vector2(30, -15), o + Vector2(60, 0), o + Vector2(80, -10)])
  draw_multiline(ml, Color.ORANGE, 2.0)
  draw_string(font, o + Vector2(0, 14), "draw_multiline", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
