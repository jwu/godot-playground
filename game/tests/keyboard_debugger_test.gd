extends GdUnitTestSuite
## KeyboardDebugger 实体的单元测试

const KEYBOARD_SCENE := preload("res://entities/keyboard_debugger.tscn")
const KeyboardDebuggerEntity := preload("res://entities/keyboard_debugger.gd")


func test_scene_has_editor_placeholder_before_ready() -> void:
  var keyboard: KeyboardDebuggerEntity = auto_free(KEYBOARD_SCENE.instantiate()) as KeyboardDebuggerEntity

  assert_str(keyboard.name).is_equal("KeyboardDebugger")
  assert_object(keyboard.get_node_or_null("EditorPlaceholder")).is_not_null()


func test_runtime_replaces_placeholder_with_keyboard_layout() -> void:
  var keyboard: KeyboardDebuggerEntity = auto_free(KEYBOARD_SCENE.instantiate()) as KeyboardDebuggerEntity
  add_child(keyboard)
  await get_tree().process_frame

  var panel: PanelContainer = keyboard.get_node_or_null("KeyboardPanel") as PanelContainer
  var rows: VBoxContainer = keyboard.get_node_or_null("KeyboardPanel/Rows") as VBoxContainer

  assert_object(keyboard.get_node_or_null("EditorPlaceholder")).is_null()
  assert_object(panel).is_not_null()
  assert_object(rows).is_not_null()
  assert_int(rows.get_child_count()).is_equal(5)


func test_key_press_highlights_and_release_restores_key() -> void:
  var keyboard: KeyboardDebuggerEntity = auto_free(KEYBOARD_SCENE.instantiate()) as KeyboardDebuggerEntity
  add_child(keyboard)
  await get_tree().process_frame

  var key_panel: PanelContainer = _find_key_panel_by_label(keyboard, "A")
  assert_object(key_panel).is_not_null()

  var normal_style: StyleBoxFlat = key_panel.get_theme_stylebox("panel") as StyleBoxFlat
  var normal_bg: Color = normal_style.bg_color

  var press_event := InputEventKey.new()
  press_event.keycode = KEY_A
  press_event.physical_keycode = KEY_A
  press_event.key_label = KEY_A
  press_event.pressed = true
  keyboard.handle_input_event(press_event)

  var pressed_style: StyleBoxFlat = key_panel.get_theme_stylebox("panel") as StyleBoxFlat
  assert_float(pressed_style.bg_color.g).is_greater(normal_bg.g)

  var release_event := InputEventKey.new()
  release_event.keycode = KEY_A
  release_event.physical_keycode = KEY_A
  release_event.key_label = KEY_A
  release_event.pressed = false
  keyboard.handle_input_event(release_event)

  var released_style: StyleBoxFlat = key_panel.get_theme_stylebox("panel") as StyleBoxFlat
  assert_float(released_style.bg_color.g).is_equal_approx(normal_bg.g, 0.001)


func test_echo_key_event_is_ignored() -> void:
  var keyboard: KeyboardDebuggerEntity = auto_free(KEYBOARD_SCENE.instantiate()) as KeyboardDebuggerEntity
  add_child(keyboard)
  await get_tree().process_frame

  var key_panel: PanelContainer = _find_key_panel_by_label(keyboard, "A")
  assert_object(key_panel).is_not_null()

  var normal_style: StyleBoxFlat = key_panel.get_theme_stylebox("panel") as StyleBoxFlat
  var normal_bg: Color = normal_style.bg_color

  var echo_event := InputEventKey.new()
  echo_event.keycode = KEY_A
  echo_event.physical_keycode = KEY_A
  echo_event.key_label = KEY_A
  echo_event.pressed = true
  echo_event.echo = true
  keyboard.handle_input_event(echo_event)

  var after_echo_style: StyleBoxFlat = key_panel.get_theme_stylebox("panel") as StyleBoxFlat
  assert_float(after_echo_style.bg_color.g).is_equal_approx(normal_bg.g, 0.001)


func _find_key_panel_by_label(root: Node, label_text: String) -> PanelContainer:
  for child: Node in root.get_children():
    if child is PanelContainer:
      var label: Label = child.get_node_or_null("Label") as Label
      if label != null and label.text == label_text:
        return child as PanelContainer

    var result: PanelContainer = _find_key_panel_by_label(child, label_text)
    if result != null:
      return result

  return null
