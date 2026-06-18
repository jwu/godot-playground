extends Control

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720


func _ready() -> void:
  # 检测系统 DPI 缩放倍数（Retina = 2.0, 普通屏 = 1.0）
  var dpi_scale := DisplayServer.screen_get_max_scale()

  # 物理窗口 = 设计分辨率 × DPI 缩放（Retina 上 2560×1440 像素 = 1280×720 系统点）
  get_window().size = Vector2i(DESIGN_WIDTH * dpi_scale, DESIGN_HEIGHT * dpi_scale)

  # 内部视口永远是 1280×720（通过 stretch 机制拉满窗口）
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

  $VBoxContainer/SampleTestBtn.pressed.connect(_on_sample_test_pressed)
  $VBoxContainer/DebugDraw2DBtn.pressed.connect(_on_debug_draw_2d_pressed)
  $VBoxContainer/DebugDraw3DBtn.pressed.connect(_on_debug_draw_3d_pressed)
  $VBoxContainer/DebugInputBtn.pressed.connect(_on_debug_input_pressed)
  $VBoxContainer/QuitBtn.pressed.connect(_on_quit_pressed)
  _update_size_display()
  get_tree().root.size_changed.connect(_update_size_display)


func _update_size_display() -> void:
  var win_size := get_window().size
  var win_mode := get_window().mode
  var vp_size := get_viewport().get_visible_rect().size
  var dpi_scale := DisplayServer.screen_get_max_scale()
  $VBoxContainer/SizeInfo.text = "DPI Scale: %.0fx\nWindow: %dx%d\nViewport: %dx%d\nMode: %s" % [dpi_scale, win_size.x, win_size.y, vp_size.x, vp_size.y, ["Windowed", "Minimized", "Maximized", "Fullscreen", "Exclusive Fullscreen"][win_mode]]


func _on_sample_test_pressed() -> void:
  get_tree().change_scene_to_file("res://scenes/sample_test.tscn")


func _on_debug_draw_2d_pressed() -> void:
  get_tree().change_scene_to_file("res://scenes/debug_draw_2d.tscn")


func _on_debug_draw_3d_pressed() -> void:
  get_tree().change_scene_to_file("res://scenes/debug_draw_3d.tscn")


func _on_debug_input_pressed() -> void:
  get_tree().change_scene_to_file("res://scenes/debug_input.tscn")


func _on_quit_pressed() -> void:
  get_tree().quit()
