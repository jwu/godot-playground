extends SceneTree
## EndlessGrid3D LOD 调试对比截图预设。
##
## 用法：
## godot --path game --script res://tools/capture_grid_compare.gd
##
## 输出：
##   res://reports/grid_lod_capture/grid_debug_off.png
##   res://reports/grid_lod_capture/grid_debug_on.png
##
## 注意：截图需要真实图形后端，不要加 --headless。

const CapturePng := preload("res://tools/capture_png.gd")
const SCENE_PATH := "res://scenes/debug_draw_3d.tscn"
const OUT_DIR := "res://reports/grid_lod_capture"
const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const WAIT_FRAMES := 20


func _initialize() -> void:
  var err := await _capture(false, "grid_debug_off.png")
  if err != OK:
    quit(err)
    return

  err = await _capture(true, "grid_debug_on.png")
  quit(err)


func _capture(debug_colors: bool, file_name: String) -> int:
  root.size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)

  var packed_scene: PackedScene = load(SCENE_PATH)
  if packed_scene == null:
    push_error("加载场景失败: %s" % SCENE_PATH)
    return 1

  var scene := packed_scene.instantiate()
  var free_camera := scene.get_node_or_null("FreeCamera") as FreeCamera
  var grid := scene.get_node_or_null("EndlessGrid3D")
  if free_camera == null or grid == null:
    push_error("截图场景缺少 FreeCamera 或 EndlessGrid3D")
    return 1

  free_camera.initial_distance = 0.8
  free_camera.initial_yaw = deg_to_rad(-32.0)
  free_camera.initial_pitch = deg_to_rad(42.0)
  free_camera.initial_target = Vector3.ZERO
  grid.set("debug_lod_colors", debug_colors)

  root.add_child(scene)
  for i in range(WAIT_FRAMES):
    await process_frame

  var err := CapturePng.save_viewport(root, OUT_DIR.path_join(file_name))
  if err != OK:
    return err

  scene.queue_free()
  for i in range(3):
    await process_frame

  return OK
