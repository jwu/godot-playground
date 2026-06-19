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

  var viewport_texture := root.get_texture()
  if viewport_texture == null:
    push_error("无法读取 viewport texture。请确认没有使用 --headless。")
    return 1

  var image := viewport_texture.get_image()
  if image == null:
    push_error("无法读取截图 image。请确认没有使用 --headless。")
    return 1

  var output_path := OUT_DIR.path_join(file_name)
  var output_global := ProjectSettings.globalize_path(output_path)
  DirAccess.make_dir_recursive_absolute(output_global.get_base_dir())
  var save_err := image.save_png(output_global)
  if save_err != OK:
    push_error("保存截图失败: %s err=%s" % [output_path, save_err])
    return 1

  print("saved ", output_global)

  scene.queue_free()
  for i in range(3):
    await process_frame

  return OK
