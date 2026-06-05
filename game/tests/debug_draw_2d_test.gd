extends GdUnitTestSuite
## DebugDraw2D 场景的单元测试
##
## 测试运行方式：
##   GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --add tests/debug_draw_2d_test.gd


# ── 场景加载 & 状态测试 ─────────────────────────────────
## 加载 DebugDraw2D 场景，验证场景和关键节点存在
func test_scene_loads() -> void:
  var runner := scene_runner("res://scenes/debug_draw_2d.tscn")
  var scene := runner.scene()
  assert_object(scene).is_not_null()
  assert_str(scene.name).is_equal("DebugDraw2D")

  assert_bool(scene.has_node("Toolbar/BackBtn")).is_true()
  assert_bool(scene.has_node("Toolbar/ColorPicker")).is_true()
  assert_bool(scene.has_node("Toolbar/WidthSlider")).is_true()
  assert_bool(scene.has_node("Toolbar/ClearBtn")).is_true()
  assert_bool(scene.has_node("Toolbar/DemoToggle")).is_true()


## 验证初始状态
func test_initial_state() -> void:
  var runner := scene_runner("res://scenes/debug_draw_2d.tscn")
  var scene := runner.scene()
  assert_int(scene.get_line_count()).is_equal(0)
  assert_float(scene.get_line_width()).is_equal(2.0)
  assert_bool(scene.is_demo_visible()).is_true()


# ── 交互逻辑测试 ────────────────────────────────────────
## 测试 Demo 开关切换
func test_demo_toggle() -> void:
  var runner := scene_runner("res://scenes/debug_draw_2d.tscn")
  var scene := runner.scene()

  assert_bool(scene.is_demo_visible()).is_true()

  var toggle := scene.get_node("Toolbar/DemoToggle") as CheckButton
  toggle.button_pressed = false
  await get_tree().process_frame
  assert_bool(scene.is_demo_visible()).is_false()

  toggle.button_pressed = true
  await get_tree().process_frame
  assert_bool(scene.is_demo_visible()).is_true()


## 测试 Clear 按钮清除线条
func test_clear_button() -> void:
  var runner := scene_runner("res://scenes/debug_draw_2d.tscn")
  var scene := runner.scene()

  assert_int(scene.get_line_count()).is_equal(0)

  var clear_btn := scene.get_node("Toolbar/ClearBtn") as Button
  clear_btn.emit_signal("pressed")
  await get_tree().process_frame
  assert_int(scene.get_line_count()).is_equal(0)


## 测试颜色选择器
func test_color_selection() -> void:
  var runner := scene_runner("res://scenes/debug_draw_2d.tscn")
  var scene := runner.scene()

  var picker := scene.get_node("Toolbar/ColorPicker") as OptionButton

  # 注意：gdUnit 测试环境下 OptionButton.select() 不触发 item_selected 信号
  # 需用 Signal.emit() 直接触发
  picker.item_selected.emit(1)
  await get_tree().process_frame
  assert_float(scene.get_current_color().g).is_equal(1.0)
  assert_float(scene.get_current_color().r).is_equal(0.0)

  picker.item_selected.emit(2)
  await get_tree().process_frame
  assert_float(scene.get_current_color().b).is_equal(1.0)
  assert_float(scene.get_current_color().r).is_equal(0.0)


## 测试线宽滑块变化
func test_width_change() -> void:
  var runner := scene_runner("res://scenes/debug_draw_2d.tscn")
  var scene := runner.scene()

  var slider := scene.get_node("Toolbar/WidthSlider") as HSlider

  slider.value = 5.0
  await get_tree().process_frame
  assert_float(scene.get_line_width()).is_equal(5.0)

  slider.value = 10.5
  await get_tree().process_frame
  assert_float(scene.get_line_width()).is_equal(10.5)


# ── 鼠标画线模拟测试 ────────────────────────────────────
## 测试鼠标按下-移动-释放画线流程
func test_mouse_draw_line() -> void:
  var runner := scene_runner("res://scenes/debug_draw_2d.tscn")
  var scene := runner.scene()

  assert_int(scene.get_line_count()).is_equal(0)

  # 1. 先把鼠标放到画布区域
  runner.set_mouse_position(Vector2(200, 200))
  await get_tree().process_frame

  # 2. 按住左键（注意：用 press 不是 pressed，后者是按下后立即释放）
  runner.simulate_mouse_button_press(MOUSE_BUTTON_LEFT)
  await get_tree().process_frame

  # 3. 移动鼠标（画线的轨迹）
  runner.simulate_mouse_move(Vector2(250, 220))
  await get_tree().process_frame
  runner.simulate_mouse_move(Vector2(300, 250))
  await get_tree().process_frame

  # 4. 释放左键
  runner.simulate_mouse_button_release(MOUSE_BUTTON_LEFT)
  await get_tree().process_frame

  assert_int(scene.get_line_count()).is_equal(1)


## 测试多笔画线条
func test_multiple_strokes() -> void:
  var runner := scene_runner("res://scenes/debug_draw_2d.tscn")
  var scene := runner.scene()

  # 第一笔
  runner.set_mouse_position(Vector2(100, 100))
  await get_tree().process_frame
  runner.simulate_mouse_button_press(MOUSE_BUTTON_LEFT)
  await get_tree().process_frame
  runner.simulate_mouse_move(Vector2(150, 150))
  await get_tree().process_frame
  runner.simulate_mouse_button_release(MOUSE_BUTTON_LEFT)
  await get_tree().process_frame

  # 第二笔
  runner.set_mouse_position(Vector2(400, 400))
  await get_tree().process_frame
  runner.simulate_mouse_button_press(MOUSE_BUTTON_LEFT)
  await get_tree().process_frame
  runner.simulate_mouse_move(Vector2(500, 450))
  await get_tree().process_frame
  runner.simulate_mouse_button_release(MOUSE_BUTTON_LEFT)
  await get_tree().process_frame

  assert_int(scene.get_line_count()).is_equal(2)


# ── Back 按钮测试 ───────────────────────────────────────
## 测试 Back 按钮存在且连接了信号
func test_back_button_exists() -> void:
  var runner := scene_runner("res://scenes/debug_draw_2d.tscn")
  var scene := runner.scene()

  var back_btn := scene.get_node("Toolbar/BackBtn") as Button
  assert_object(back_btn).is_not_null()
  assert_str(back_btn.text).is_equal("Back")
  # 验证按钮有至少一个 pressed 信号连接
  assert_bool(back_btn.pressed.get_connections().size() > 0).is_true()
