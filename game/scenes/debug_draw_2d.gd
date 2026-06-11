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
const GRID_LOD_MIN_PIXELS := 3.0
const GRID_LINE_WIDTH_PIXELS := 1.0
const PAN_ZOOM_BASE := 1.05
const PAN_ZOOM_MAX_STEPS := 6.0
const MIN_ZOOM := 0.05
const MAX_ZOOM := 100.0

var _last_displayed_zoom := -1.0

@onready var _zoom_label: Label = $UI/ZoomLabel as Label


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

  # dashed line 动画需要持续重绘。
  queue_redraw()


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


func _draw() -> void:
  _draw_grid()
  _draw_demos()


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
    vp_size,
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
  var lod1_middle_color := GRID_COLOR_MAJOR.lerp(GRID_COLOR, lod_fade)
  lod1_middle_color.a *= 5.0

  _draw_grid_level(bounds, lod0_spacing, lod0_color, line_width)
  _draw_grid_level(bounds, lod1_spacing, lod1_color, line_width)
  # lod1 相对上一级 lod2 的中线：每个 lod2 大格内部第 5 条 lod1 线。
  _draw_grid_level_with_offset(bounds, lod2_spacing, lod2_spacing * 0.5, lod1_middle_color, line_width)
  _draw_grid_level(bounds, lod2_spacing, GRID_COLOR_MAJOR, line_width)


func _draw_grid_level(bounds: Rect2, spacing: float, color: Color, line_width: float) -> void:
  _draw_grid_level_with_offset(bounds, spacing, 0.0, color, line_width)


func _draw_grid_level_with_offset(bounds: Rect2, spacing: float, offset: float, color: Color, line_width: float) -> void:
  if spacing <= 0.0 or color.a <= 0.001:
    return

  var left := bounds.position.x
  var right := bounds.end.x
  var top := bounds.position.y
  var bottom := bounds.end.y

  var x: float = floor((left - offset) / spacing) * spacing + offset
  while x <= right:
    draw_line(Vector2(x, top), Vector2(x, bottom), color, line_width, true)
    x += spacing

  var y: float = floor((top - offset) / spacing) * spacing + offset
  while y <= bottom:
    draw_line(Vector2(left, y), Vector2(right, y), color, line_width, true)
    y += spacing


func _draw_demos() -> void:
  _draw_line_demos(Vector2(-580, -220))
  _draw_dashed_line_demos(Vector2(-260, -220))
  _draw_polyline_demos(Vector2(60, -220))
  _draw_multiline_demos(Vector2(380, -220))
  _draw_rect_demos(Vector2(700, -220))
  _draw_circle_demos(Vector2(1020, -220))
  _draw_ellipse_demos(Vector2(1340, -220))
  _draw_arc_demos(Vector2(1660, -220))
  _draw_ellipse_arc_demos(Vector2(1980, -220))
  _draw_polygon_demos(Vector2(2300, -220))
  _draw_primitive_demos(Vector2(2620, -220))


func _draw_line_demos(origin: Vector2) -> void:
  var gap := 60.0
  var font := ThemeDB.fallback_font
  var len := 100.0
  var line_delta := Vector2(len, -40.0)
  var label_offset := Vector2(len + 8, -6)
  var title := "draw_line"
  var title_font_size := 16
  var o := origin + Vector2(0.0, font.get_height(title_font_size) + 28.0)

  draw_string(font, origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)

  # 1. width=-1
  draw_line(o, o + line_delta, Color.WHITE, -1.0)
  draw_string(font, o + label_offset, "width=-1 (1px)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 2. width=1, no aa
  o.y += gap
  draw_line(o, o + line_delta, Color.RED, 1.0)
  draw_string(font, o + label_offset, "width=1, aa=false", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 3. width=1, aa
  o.y += gap
  draw_line(o, o + line_delta, Color.GREEN, 1.0, true)
  draw_string(font, o + label_offset, "width=1, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 4. width=3
  o.y += gap
  draw_line(o, o + line_delta, Color.BLUE, 3.0)
  draw_string(font, o + label_offset, "width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 5. width=6, aa
  o.y += gap
  draw_line(o, o + line_delta, Color.YELLOW, 6.0, true)
  draw_string(font, o + label_offset, "width=6, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 6. width=12, aa
  o.y += gap
  draw_line(o, o + line_delta, Color.MAGENTA, 12.0, true)
  draw_string(font, o + label_offset, "width=12, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _draw_dashed_line_demos(origin: Vector2) -> void:
  var gap := 60.0
  var font := ThemeDB.fallback_font
  var len := 100.0
  var line_delta := Vector2(len, -40.0)
  var label_offset := Vector2(len + 8, -6)
  var dash := 12.0
  var title := "draw_dashed_line"
  var title_font_size := 16
  var o := origin + Vector2(0.0, font.get_height(title_font_size) + 28.0)

  draw_string(font, origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)

  # 1. width=-1
  draw_dashed_line(o, o + line_delta, Color.WHITE, -1.0, dash, true)
  draw_string(font, o + label_offset, "width=-1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 2. width=1, no aa
  o.y += gap
  draw_dashed_line(o, o + line_delta, Color.RED, 1.0, dash, true)
  draw_string(font, o + label_offset, "width=1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 3. width=1, aa
  o.y += gap
  draw_dashed_line(o, o + line_delta, Color.GREEN, 1.0, dash, true, true)
  draw_string(font, o + label_offset, "width=1, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 4. width=3
  o.y += gap
  draw_dashed_line(o, o + line_delta, Color.BLUE, 3.0, dash, true)
  draw_string(font, o + label_offset, "width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 5. width=6, aa
  o.y += gap
  draw_dashed_line(o, o + line_delta, Color.YELLOW, 6.0, dash, true, true)
  draw_string(font, o + label_offset, "width=6, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 6. width=12, aa
  o.y += gap
  draw_dashed_line(o, o + line_delta, Color.MAGENTA, 12.0, dash, true, true)
  draw_string(font, o + label_offset, "width=12, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 7. dash=4
  o.y += gap
  draw_dashed_line(o, o + line_delta, Color.CYAN, 3.0, 4.0, true, true)
  draw_string(font, o + label_offset, "dash=4, width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 8. dash=8
  o.y += gap
  draw_dashed_line(o, o + line_delta, Color.ORANGE, 3.0, 8.0, true, true)
  draw_string(font, o + label_offset, "dash=8, width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 9. dash=24
  o.y += gap
  draw_dashed_line(o, o + line_delta, Color.DEEP_SKY_BLUE, 3.0, 24.0, true, true)
  draw_string(font, o + label_offset, "dash=24, width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 10. len 动画，dash 使用默认值，对比 aligned=true/false
  o.y += gap
  var animated_len := lerpf(30.0, 140.0, (sin(Time.get_ticks_msec() * 0.004) + 1.0) * 0.5)
  var animated_line_delta := Vector2(animated_len, -40.0)
  draw_dashed_line(o, o + animated_line_delta, Color.PINK, 3.0, dash, true, true)
  draw_string(font, o + label_offset, "aligned=true, len=%.1f" % animated_len, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  var unaligned_o := o + Vector2(0.0, 28.0)
  draw_dashed_line(unaligned_o, unaligned_o + animated_line_delta, Color.PINK, 3.0, dash, false, true)
  draw_string(font, unaligned_o + label_offset, "aligned=false, len=%.1f" % animated_len, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _draw_polyline_demos(origin: Vector2) -> void:
  var gap := 60.0
  var font := ThemeDB.fallback_font
  var len := 100.0
  var label_offset := Vector2(len + 8, -6)
  var title := "draw_polyline"
  var title_font_size := 16
  var o := origin + Vector2(0.0, font.get_height(title_font_size) + 28.0)

  draw_string(font, origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)

  # 1. width=-1
  draw_polyline(_make_polyline_points(o), Color.WHITE, -1.0)
  draw_string(font, o + label_offset, "width=-1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 2. width=1, no aa
  o.y += gap
  draw_polyline(_make_polyline_points(o), Color.RED, 1.0)
  draw_string(font, o + label_offset, "width=1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 3. width=1, aa
  o.y += gap
  draw_polyline(_make_polyline_points(o), Color.GREEN, 1.0, true)
  draw_string(font, o + label_offset, "width=1, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 4. width=3
  o.y += gap
  draw_polyline(_make_polyline_points(o), Color.BLUE, 3.0)
  draw_string(font, o + label_offset, "width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 5. width=6, aa
  o.y += gap
  draw_polyline(_make_polyline_points(o), Color.YELLOW, 6.0, true)
  draw_string(font, o + label_offset, "width=6, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 6. width=12, aa
  o.y += gap
  draw_polyline(_make_polyline_points(o), Color.MAGENTA, 12.0, true)
  draw_string(font, o + label_offset, "width=12, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 7. draw_polyline_colors
  o.y += gap
  draw_polyline_colors(_make_polyline_points(o), _make_demo_colors(), 3.0, true)
  draw_string(font, o + label_offset, "colors, width=3, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 8. draw_polyline_colors, width=8
  o.y += gap
  draw_polyline_colors(_make_polyline_points(o), _make_demo_colors(), 8.0, true)
  draw_string(font, o + label_offset, "colors, width=8, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _draw_multiline_demos(origin: Vector2) -> void:
  var gap := 60.0
  var font := ThemeDB.fallback_font
  var len := 100.0
  var label_offset := Vector2(len + 8, -6)
  var title := "draw_multiline"
  var title_font_size := 16
  var o := origin + Vector2(0.0, font.get_height(title_font_size) + 28.0)

  draw_string(font, origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)

  # 1. width=-1
  draw_multiline(_make_multiline_points(o), Color.WHITE, -1.0)
  draw_string(font, o + label_offset, "width=-1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 2. width=1, no aa
  o.y += gap
  draw_multiline(_make_multiline_points(o), Color.RED, 1.0)
  draw_string(font, o + label_offset, "width=1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 3. width=1, aa
  o.y += gap
  draw_multiline(_make_multiline_points(o), Color.GREEN, 1.0, true)
  draw_string(font, o + label_offset, "width=1, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 4. width=3
  o.y += gap
  draw_multiline(_make_multiline_points(o), Color.BLUE, 3.0)
  draw_string(font, o + label_offset, "width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 5. width=6, aa
  o.y += gap
  draw_multiline(_make_multiline_points(o), Color.YELLOW, 6.0, true)
  draw_string(font, o + label_offset, "width=6, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 6. width=12, aa
  o.y += gap
  draw_multiline(_make_multiline_points(o), Color.MAGENTA, 12.0, true)
  draw_string(font, o + label_offset, "width=12, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 7. draw_multiline_colors
  o.y += gap
  draw_multiline_colors(_make_multiline_points(o), _make_multiline_demo_colors(), 3.0, true)
  draw_string(font, o + label_offset, "colors, width=3, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  # 8. draw_multiline_colors, width=8
  o.y += gap
  draw_multiline_colors(_make_multiline_points(o), _make_multiline_demo_colors(), 8.0, true)
  draw_string(font, o + label_offset, "colors, width=8, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _draw_rect_demos(origin: Vector2) -> void:
  var gap := 76.0
  var font := ThemeDB.fallback_font
  var label_offset := Vector2(118.0, 12.0)
  var title := "draw_rect"
  var title_font_size := 16
  var o := origin + Vector2(0.0, font.get_height(title_font_size) + 28.0)

  draw_string(font, origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)

  var rect := Rect2(o, Vector2(90.0, 45.0))
  draw_rect(rect, Color(1.0, 1.0, 1.0, 0.2), true)
  draw_string(font, o + label_offset, "filled=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  rect = Rect2(o, Vector2(90.0, 45.0))
  draw_rect(rect, Color.RED, false, 3.0)
  draw_string(font, o + label_offset, "filled=false, width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  rect = Rect2(o, Vector2(90.0, 45.0))
  draw_rect(rect, Color.GREEN, false, 6.0, true)
  draw_string(font, o + label_offset, "width=6, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _draw_circle_demos(origin: Vector2) -> void:
  var gap := 76.0
  var font := ThemeDB.fallback_font
  var label_offset := Vector2(118.0, 12.0)
  var title := "draw_circle"
  var title_font_size := 16
  var o := origin + Vector2(45.0, font.get_height(title_font_size) + 50.0)

  draw_string(font, origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)

  draw_circle(o, 28.0, Color.WHITE, true)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "filled=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_circle(o, 28.0, Color.RED, false, 3.0)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "filled=false, width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_circle(o, 28.0, Color.GREEN, false, 6.0, true)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "width=6, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _draw_ellipse_demos(origin: Vector2) -> void:
  var gap := 76.0
  var font := ThemeDB.fallback_font
  var label_offset := Vector2(118.0, 12.0)
  var title := "draw_ellipse"
  var title_font_size := 16
  var o := origin + Vector2(45.0, font.get_height(title_font_size) + 50.0)

  draw_string(font, origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)

  draw_ellipse(o, 45.0, 24.0, Color.WHITE, true)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "filled=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_ellipse(o, 45.0, 24.0, Color.RED, false, 3.0)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "filled=false, width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_ellipse(o, 45.0, 24.0, Color.GREEN, false, 6.0, true)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "width=6, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _draw_arc_demos(origin: Vector2) -> void:
  var gap := 76.0
  var font := ThemeDB.fallback_font
  var label_offset := Vector2(118.0, 12.0)
  var title := "draw_arc"
  var title_font_size := 16
  var o := origin + Vector2(45.0, font.get_height(title_font_size) + 50.0)

  draw_string(font, origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)

  draw_arc(o, 34.0, 0.0, PI * 1.5, 32, Color.WHITE, -1.0)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "width=-1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_arc(o, 34.0, 0.0, PI * 1.5, 32, Color.RED, 3.0)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_arc(o, 34.0, 0.0, PI * 1.5, 32, Color.GREEN, 6.0, true)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "width=6, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _draw_ellipse_arc_demos(origin: Vector2) -> void:
  var gap := 76.0
  var font := ThemeDB.fallback_font
  var label_offset := Vector2(118.0, 12.0)
  var title := "draw_ellipse_arc"
  var title_font_size := 16
  var o := origin + Vector2(45.0, font.get_height(title_font_size) + 50.0)

  draw_string(font, origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)

  draw_ellipse_arc(o, 45.0, 24.0, 0.0, PI * 1.5, 32, Color.WHITE, -1.0)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "width=-1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_ellipse_arc(o, 45.0, 24.0, 0.0, PI * 1.5, 32, Color.RED, 3.0)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "width=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_ellipse_arc(o, 45.0, 24.0, 0.0, PI * 1.5, 32, Color.GREEN, 6.0, true)
  draw_string(font, o + label_offset - Vector2(45.0, 22.0), "width=6, aa=true", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _draw_polygon_demos(origin: Vector2) -> void:
  var gap := 76.0
  var font := ThemeDB.fallback_font
  var label_offset := Vector2(118.0, 12.0)
  var title := "draw_polygon"
  var title_font_size := 16
  var o := origin + Vector2(0.0, font.get_height(title_font_size) + 28.0)

  draw_string(font, origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)

  draw_polygon(_make_triangle_points(o), PackedColorArray([Color(1.0, 1.0, 1.0, 0.35)]))
  draw_polyline(_make_closed_triangle_points(o), Color.WHITE, 2.0, true)
  draw_string(font, o + label_offset, "single color", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_polygon(_make_triangle_points(o), PackedColorArray([Color.RED, Color.GREEN, Color.BLUE]))
  draw_string(font, o + label_offset, "vertex colors", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_colored_polygon(_make_quad_points(o), Color(1.0, 0.75, 0.1, 0.45))
  draw_polyline(_make_closed_quad_points(o), Color.ORANGE, 2.0, true)
  draw_string(font, o + label_offset, "draw_colored_polygon", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_colored_polygon(_make_triangle_points(o), Color(0.1, 0.8, 1.0, 0.45))
  draw_polyline(_make_closed_triangle_points(o), Color.CYAN, 2.0, true)
  draw_string(font, o + label_offset, "colored triangle", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _draw_primitive_demos(origin: Vector2) -> void:
  var gap := 76.0
  var font := ThemeDB.fallback_font
  var label_offset := Vector2(118.0, 12.0)
  var title := "draw_primitive"
  var title_font_size := 16
  var o := origin + Vector2(0.0, font.get_height(title_font_size) + 28.0)

  draw_string(font, origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size)

  draw_primitive(_make_triangle_points(o), PackedColorArray([Color.CYAN, Color.MAGENTA, Color.YELLOW]), PackedVector2Array())
  draw_string(font, o + label_offset, "triangle", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

  o.y += gap
  draw_primitive(_make_quad_points(o), PackedColorArray([Color.RED, Color.YELLOW, Color.GREEN, Color.BLUE]), PackedVector2Array())
  draw_string(font, o + label_offset, "quad", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)


func _make_polyline_points(origin: Vector2) -> PackedVector2Array:
  return PackedVector2Array(
    [
      origin,
      origin + Vector2(30.0, -40.0),
      origin + Vector2(65.0, 0.0),
      origin + Vector2(100.0, -40.0),
    ],
  )


func _make_multiline_points(origin: Vector2) -> PackedVector2Array:
  return PackedVector2Array(
    [
      origin,
      origin + Vector2(45.0, -40.0),
      origin + Vector2(55.0, 0.0),
      origin + Vector2(100.0, -40.0),
    ],
  )


func _make_triangle_points(origin: Vector2) -> PackedVector2Array:
  return PackedVector2Array(
    [
      origin + Vector2(45.0, 0.0),
      origin + Vector2(0.0, 52.0),
      origin + Vector2(90.0, 52.0),
    ],
  )


func _make_closed_triangle_points(origin: Vector2) -> PackedVector2Array:
  var points := _make_triangle_points(origin)
  points.push_back(points[0])
  return points


func _make_quad_points(origin: Vector2) -> PackedVector2Array:
  return PackedVector2Array(
    [
      origin + Vector2(10.0, 4.0),
      origin + Vector2(88.0, 12.0),
      origin + Vector2(76.0, 54.0),
      origin + Vector2(0.0, 46.0),
    ],
  )


func _make_closed_quad_points(origin: Vector2) -> PackedVector2Array:
  var points := _make_quad_points(origin)
  points.push_back(points[0])
  return points


func _make_demo_colors() -> PackedColorArray:
  return PackedColorArray(
    [
      Color.RED,
      Color.YELLOW,
      Color.GREEN,
      Color.CYAN,
    ],
  )


func _make_multiline_demo_colors() -> PackedColorArray:
  return PackedColorArray(
    [
      Color.ORANGE,
      Color.CYAN,
    ],
  )
