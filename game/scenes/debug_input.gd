extends Control
## DebugInput：捕获所有 InputEvent 并实时打印到屏幕
##
## 用于诊断 Mac 触控板 / 鼠标 / 键盘产生的事件类型。

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const LoggerEntity := preload("res://entities/logger.gd")

@onready var _logger: LoggerEntity = $Logger as LoggerEntity
@onready var _keyboard_debugger := $KeyboardDebugger


func _ready() -> void:
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(DESIGN_WIDTH * dpi_scale, DESIGN_HEIGHT * dpi_scale)
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _input(event: InputEvent) -> void:
  _keyboard_debugger.handle_input_event(event)

  if event.is_action_pressed(&"ui_cancel"):
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
    return

  _logger.log(_format_event(event))


func _format_event(event: InputEvent) -> String:
  var ts := Time.get_ticks_msec() % 100000 # 取后 5 位毫秒
  var prefix := "[%05d] " % ts

  # InputEventMouseButton
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
    var pos := get_viewport().get_mouse_position()
    return prefix + "MouseButton  %s %s  pos=(%.0f, %.0f)" % [btn, action, pos.x, pos.y]

  # InputEventMouseMotion
  if event is InputEventMouseMotion:
    var vel: Vector2 = event.velocity if "velocity" in event else Vector2.ZERO
    return prefix + "MouseMotion  pos=(%.0f, %.0f)  rel=(%.1f, %.1f)" % [event.position.x, event.position.y, event.relative.x, event.relative.y]

  # InputEventPanGesture
  if event is InputEventPanGesture:
    return prefix + "PanGesture  delta=(%.1f, %.1f)" % [event.delta.x, event.delta.y]

  # InputEventMagnifyGesture
  if event is InputEventMagnifyGesture:
    return prefix + "MagnifyGesture  factor=%.4f" % event.factor

  # InputEventKey
  if event is InputEventKey:
    var key_str := OS.get_keycode_string(event.keycode) if not event.key_label else OS.get_keycode_string(event.key_label)
    var action := "press" if event.pressed else "release"
    return prefix + "Key  %s  %s  echo=%s" % [key_str, action, event.echo]

  # InputEventJoypadButton / InputEventJoypadMotion
  if event is InputEventJoypadButton:
    return prefix + "JoyButton  btn=%d  press=%s" % [event.button_index, event.pressed]

  if event is InputEventJoypadMotion:
    return prefix + "JoyMotion  axis=%d  val=%.2f" % [event.axis, event.axis_value]

  # 兜底：用 as_text()
  return prefix + event.as_text()
