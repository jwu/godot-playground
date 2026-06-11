extends Control
## KeyboardDebugger：屏幕键盘输入可视化组件。
##
## 作为可复用实体放在右下角，用 handle_input_event() 接收键盘事件并高亮对应按键。

const KEY_UNIT := 34.0
const KEY_HEIGHT := 30.0
const KEY_GAP := 4
const PANEL_SIZE := Vector2(640, 218)

var _normal_style := StyleBoxFlat.new()
var _pressed_style := StyleBoxFlat.new()
var _panel_style := StyleBoxFlat.new()
var _key_nodes: Dictionary = {}


func _ready() -> void:
  mouse_filter = Control.MOUSE_FILTER_IGNORE
  custom_minimum_size = PANEL_SIZE
  size = PANEL_SIZE

  if Engine.is_editor_hint():
    _remove_runtime_keyboard()
    _show_editor_placeholder()
    return

  _remove_editor_placeholder()
  _remove_runtime_keyboard()
  _setup_styles()
  _build_layout()


func handle_input_event(event: InputEvent) -> void:
  if not event is InputEventKey:
    return

  var key_event := event as InputEventKey
  if key_event.echo:
    return

  var codes: Array[int] = []
  _append_key_code(codes, key_event.keycode)
  _append_key_code(codes, key_event.physical_keycode)
  _append_key_code(codes, key_event.key_label)

  for code in codes:
    _set_key_pressed(code, key_event.pressed)


func _remove_runtime_keyboard() -> void:
  _key_nodes.clear()

  var keyboard_panel := get_node_or_null("KeyboardPanel")
  if keyboard_panel == null:
    return

  remove_child(keyboard_panel)
  keyboard_panel.queue_free()


func _remove_editor_placeholder() -> void:
  var placeholder := get_node_or_null("EditorPlaceholder")
  if placeholder == null:
    return

  remove_child(placeholder)
  placeholder.queue_free()


func _show_editor_placeholder() -> void:
  var existing_placeholder := get_node_or_null("EditorPlaceholder") as Control
  if existing_placeholder != null:
    existing_placeholder.visible = true
    return

  var placeholder_style := StyleBoxFlat.new()
  placeholder_style.bg_color = Color(0.08, 0.10, 0.14, 0.78)
  placeholder_style.border_color = Color(0.35, 0.65, 1.00, 0.70)
  placeholder_style.set_border_width_all(2)
  placeholder_style.set_corner_radius_all(8)
  placeholder_style.set_content_margin_all(12)

  var panel := PanelContainer.new()
  panel.name = "EditorPlaceholder"
  panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
  panel.anchor_right = 1.0
  panel.anchor_bottom = 1.0
  panel.add_theme_stylebox_override("panel", placeholder_style)
  add_child(panel)

  var label := Label.new()
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  label.text = "Keyboard Debugger\n编辑器占位显示\n运行时显示真实键盘布局"
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  label.add_theme_font_size_override("font_size", 22)
  label.add_theme_color_override("font_color", Color(0.86, 0.94, 1.00, 1.00))
  panel.add_child(label)


func _setup_styles() -> void:
  _panel_style.bg_color = Color(0.03, 0.04, 0.06, 0.72)
  _panel_style.border_color = Color(0.35, 0.45, 0.65, 0.45)
  _panel_style.set_border_width_all(1)
  _panel_style.set_corner_radius_all(8)
  _panel_style.set_content_margin_all(8)

  _normal_style.bg_color = Color(0.10, 0.12, 0.16, 0.88)
  _normal_style.border_color = Color(0.45, 0.52, 0.65, 0.55)
  _normal_style.set_border_width_all(1)
  _normal_style.set_corner_radius_all(5)

  _pressed_style.bg_color = Color(0.18, 0.75, 1.00, 0.96)
  _pressed_style.border_color = Color(0.75, 0.95, 1.00, 1.00)
  _pressed_style.set_border_width_all(2)
  _pressed_style.set_corner_radius_all(5)


func _build_layout() -> void:
  var panel := PanelContainer.new()
  panel.name = "KeyboardPanel"
  panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
  panel.anchor_right = 1.0
  panel.anchor_bottom = 1.0
  panel.add_theme_stylebox_override("panel", _panel_style)
  add_child(panel)

  var rows := VBoxContainer.new()
  rows.name = "Rows"
  rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
  rows.add_theme_constant_override("separation", KEY_GAP)
  panel.add_child(rows)

  for row_defs in _get_keyboard_rows():
    var row := HBoxContainer.new()
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", KEY_GAP)
    rows.add_child(row)

    for key_def in row_defs:
      row.add_child(_create_key(key_def))


func _get_keyboard_rows() -> Array:
  return [
    [
      _key(KEY_ESCAPE, "Esc", 1.2), _key(KEY_QUOTELEFT, "`"), _key(KEY_1, "1"), _key(KEY_2, "2"), _key(KEY_3, "3"), _key(KEY_4, "4"), _key(KEY_5, "5"), _key(KEY_6, "6"), _key(KEY_7, "7"), _key(KEY_8, "8"), _key(KEY_9, "9"), _key(KEY_0, "0"), _key(KEY_MINUS, "-"), _key(KEY_EQUAL, "="), _key(KEY_BACKSPACE, "⌫", 1.8),
    ],
    [
      _key(KEY_TAB, "Tab", 1.5), _key(KEY_Q, "Q"), _key(KEY_W, "W"), _key(KEY_E, "E"), _key(KEY_R, "R"), _key(KEY_T, "T"), _key(KEY_Y, "Y"), _key(KEY_U, "U"), _key(KEY_I, "I"), _key(KEY_O, "O"), _key(KEY_P, "P"), _key(KEY_BRACKETLEFT, "["), _key(KEY_BRACKETRIGHT, "]"), _key(KEY_BACKSLASH, "\\"),
    ],
    [
      _key(KEY_CAPSLOCK, "Caps", 1.8), _key(KEY_A, "A"), _key(KEY_S, "S"), _key(KEY_D, "D"), _key(KEY_F, "F"), _key(KEY_G, "G"), _key(KEY_H, "H"), _key(KEY_J, "J"), _key(KEY_K, "K"), _key(KEY_L, "L"), _key(KEY_SEMICOLON, ";"), _key(KEY_APOSTROPHE, "'"), _key(KEY_ENTER, "Enter", 2.0),
    ],
    [
      _key(KEY_SHIFT, "Shift", 2.2), _key(KEY_Z, "Z"), _key(KEY_X, "X"), _key(KEY_C, "C"), _key(KEY_V, "V"), _key(KEY_B, "B"), _key(KEY_N, "N"), _key(KEY_M, "M"), _key(KEY_COMMA, ","), _key(KEY_PERIOD, "."), _key(KEY_SLASH, "/"), _key(KEY_SHIFT, "Shift", 2.2),
    ],
    [
      _key(KEY_CTRL, "Ctrl", 1.3), _key(KEY_ALT, "Alt", 1.3), _key(KEY_META, "Cmd", 1.3), _key(KEY_SPACE, "Space", 5.0), _key(KEY_META, "Cmd", 1.3), _key(KEY_ALT, "Alt", 1.3), _key(KEY_LEFT, "←"), _key(KEY_UP, "↑"), _key(KEY_DOWN, "↓"), _key(KEY_RIGHT, "→"),
    ],
  ]


func _key(code: int, label: String, width_units := 1.0) -> Dictionary:
  return {
    "code": code,
    "label": label,
    "width": width_units,
  }


func _create_key(key_def: Dictionary) -> PanelContainer:
  var key_panel := PanelContainer.new()
  key_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
  key_panel.custom_minimum_size = Vector2(KEY_UNIT * float(key_def["width"]), KEY_HEIGHT)
  key_panel.add_theme_stylebox_override("panel", _normal_style)

  var label := Label.new()
  label.name = "Label"
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  label.text = key_def["label"]
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  label.add_theme_font_size_override("font_size", 13)
  label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.00, 1.00))
  key_panel.add_child(label)

  var code := int(key_def["code"])
  if not _key_nodes.has(code):
    _key_nodes[code] = []
  _key_nodes[code].append(key_panel)

  return key_panel


func _append_key_code(codes: Array[int], code: int) -> void:
  if code == KEY_NONE:
    return
  if codes.has(code):
    return
  codes.append(code)


func _set_key_pressed(code: int, pressed: bool) -> void:
  if not _key_nodes.has(code):
    return

  for key_panel: PanelContainer in _key_nodes[code]:
    key_panel.add_theme_stylebox_override("panel", _pressed_style if pressed else _normal_style)

    var label := key_panel.get_node("Label") as Label
    var font_color := Color(0.02, 0.07, 0.10, 1.00) if pressed else Color(0.88, 0.92, 1.00, 1.00)
    label.add_theme_color_override("font_color", font_color)
