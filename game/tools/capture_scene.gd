extends SceneTree
## DebugDraw3D 固定截图脚本。
##
## 用法：godot --path game --script res://tools/capture_scene.gd
## 注意：截图需要真实图形后端，不要加 --headless。

const SCENE_PATH := "res://scenes/debug_draw_3d.tscn"
const OUT_PATH := "res://reports/captures/debug_grid.png"
const DESIGN_SIZE := Vector2i(1280, 720)
const WAIT_FRAMES := 20


func _initialize() -> void:
  quit(await _capture())


func _capture() -> int:
  root.size = DESIGN_SIZE

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
  grid.set("debug_lod_colors", false)

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

  var output_global := ProjectSettings.globalize_path(OUT_PATH)
  DirAccess.make_dir_recursive_absolute(output_global.get_base_dir())
  var save_err := image.save_png(output_global)
  if save_err != OK:
    push_error("保存截图失败: %s err=%s" % [OUT_PATH, save_err])
    return 1

  print("saved ", output_global)
  return OK
