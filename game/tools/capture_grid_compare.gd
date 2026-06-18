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

const CaptureSceneUtils := preload("res://tools/capture_scene_utils.gd")
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
  var set_expressions: Array[String] = [
    "FreeCamera.initial_distance=0.8",
    "FreeCamera.initial_yaw=-32deg",
    "FreeCamera.initial_pitch=42deg",
    "FreeCamera.initial_target=Vector3(0,0,0)",
    "EndlessGrid3D.debug_lod_colors=%s" % ["true" if debug_colors else "false"],
  ]
  if not CaptureSceneUtils.apply_set_expressions(scene, set_expressions):
    return 1

  root.add_child(scene)
  for i in range(WAIT_FRAMES):
    await process_frame

  var viewport_texture := root.get_texture()
  if viewport_texture == null:
    push_error("无法读取 viewport texture。请确认没有使用 --headless。")
    return 1

  var image := viewport_texture.get_image()
  if image == null:
    push_error("无法读取截图 image。请确认没有使用 --headless。")
    return 1

  var output_path := OUT_DIR.path_join(file_name)
  CaptureSceneUtils.ensure_output_parent(output_path)
  var save_err := image.save_png(CaptureSceneUtils.global_output_path(output_path))
  if save_err != OK:
    push_error("保存截图失败: %s err=%s" % [output_path, save_err])
    return 1

  print("saved ", CaptureSceneUtils.global_output_path(output_path))

  scene.queue_free()
  for i in range(3):
    await process_frame

  return OK
