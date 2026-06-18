extends SceneTree
## 通用场景截图工具。
##
## 示例：
## godot --path game --script res://tools/capture_scene.gd -- \
##   --scene res://scenes/debug_draw_3d.tscn \
##   --out res://reports/captures/debug_grid.png \
##   --width 1280 --height 720 --frames 20 \
##   --set FreeCamera.initial_distance=0.8 \
##   --set FreeCamera.initial_yaw=-32deg \
##   --set FreeCamera.initial_pitch=42deg \
##   --set EndlessGrid3D.debug_lod_colors=true
##
## 注意：截图需要真实图形后端，不要加 --headless。

const CaptureSceneUtils := preload("res://tools/capture_scene_utils.gd")
const DEFAULT_WIDTH := 1280
const DEFAULT_HEIGHT := 720
const DEFAULT_FRAMES := 20


func _initialize() -> void:
  var config := _parse_args(OS.get_cmdline_user_args())
  if config.get("help", false):
    _print_usage()
    quit()
    return

  if config.get("error", "") != "":
    push_error(config.error)
    _print_usage()
    quit(1)
    return

  var scene_path: String = config.get("scene", "")
  var output_path: String = config.get("out", "")
  if scene_path.is_empty() or output_path.is_empty():
    push_error("必须提供 --scene 和 --out")
    _print_usage()
    quit(1)
    return

  var err := await _capture(config)
  quit(err)


func _capture(config: Dictionary) -> int:
  root.size = Vector2i(config.get("width", DEFAULT_WIDTH), config.get("height", DEFAULT_HEIGHT))

  var packed_scene: PackedScene = load(config.scene)
  if packed_scene == null:
    push_error("加载场景失败: %s" % config.scene)
    return 1

  var scene := packed_scene.instantiate()
  var set_expressions: Array[String] = config.get("sets", [] as Array[String])
  if not CaptureSceneUtils.apply_set_expressions(scene, set_expressions):
    return 1

  root.add_child(scene)

  var frame_count: int = config.get("frames", DEFAULT_FRAMES)
  for i in range(frame_count):
    await process_frame

  var viewport_texture := root.get_texture()
  if viewport_texture == null:
    push_error("无法读取 viewport texture。请确认没有使用 --headless。")
    return 1

  var image := viewport_texture.get_image()
  if image == null:
    push_error("无法读取截图 image。请确认没有使用 --headless。")
    return 1

  var output_path: String = config.out
  CaptureSceneUtils.ensure_output_parent(output_path)
  var save_err := image.save_png(CaptureSceneUtils.global_output_path(output_path))
  if save_err != OK:
    push_error("保存截图失败: %s err=%s" % [output_path, save_err])
    return 1

  print("saved ", CaptureSceneUtils.global_output_path(output_path))
  return 0


func _parse_args(args: PackedStringArray) -> Dictionary:
  var config: Dictionary = {
    "width": DEFAULT_WIDTH,
    "height": DEFAULT_HEIGHT,
    "frames": DEFAULT_FRAMES,
    "sets": [] as Array[String],
  }

  var i := 0
  while i < args.size():
    var arg := args[i]
    match arg:
      "--help", "-h":
        config.help = true
      "--scene":
        i += 1
        if i >= args.size():
          return _arg_error("--scene 缺少值")
        config.scene = args[i]
      "--out":
        i += 1
        if i >= args.size():
          return _arg_error("--out 缺少值")
        config.out = args[i]
      "--width":
        i += 1
        if i >= args.size():
          return _arg_error("--width 缺少值")
        config.width = int(args[i])
      "--height":
        i += 1
        if i >= args.size():
          return _arg_error("--height 缺少值")
        config.height = int(args[i])
      "--frames":
        i += 1
        if i >= args.size():
          return _arg_error("--frames 缺少值")
        config.frames = int(args[i])
      "--set":
        i += 1
        if i >= args.size():
          return _arg_error("--set 缺少值")
        (config.sets as Array[String]).append(args[i])
      _:
        if arg.begins_with("--scene="):
          config.scene = arg.substr(8)
        elif arg.begins_with("--out="):
          config.out = arg.substr(6)
        elif arg.begins_with("--width="):
          config.width = int(arg.substr(8))
        elif arg.begins_with("--height="):
          config.height = int(arg.substr(9))
        elif arg.begins_with("--frames="):
          config.frames = int(arg.substr(9))
        elif arg.begins_with("--set="):
          (config.sets as Array[String]).append(arg.substr(6))
        else:
          return _arg_error("未知参数: %s" % arg)
    i += 1

  return config


func _arg_error(message: String) -> Dictionary:
  return { "error": message }


func _print_usage() -> void:
  print(
    """
用法：
  godot --path game --script res://tools/capture_scene.gd -- --scene <scene.tscn> --out <output.png> [options]

选项：
  --width <px>          截图宽度，默认 1280
  --height <px>         截图高度，默认 720
  --frames <count>      截图前等待帧数，默认 20
  --set <path.prop=val> 实例化后、进入场景树前设置节点属性，可重复

值格式：
  true / false / null / 数字 / 字符串
  -32deg 或 deg:-32 会转为弧度
  Vector3(0,0,0)、Vector2(1,2)、Color(1,1,1,0.5)

注意：截图需要真实图形后端，不要加 --headless。
""",
  )
