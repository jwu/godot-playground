extends RefCounted
## 截图脚本共用的 PNG 保存函数。


static func save_viewport(viewport: Viewport, output_path: String) -> int:
  var viewport_texture := viewport.get_texture()
  if viewport_texture == null:
    push_error("无法读取 viewport texture。请确认没有使用 --headless。")
    return 1

  var image := viewport_texture.get_image()
  if image == null:
    push_error("无法读取截图 image。请确认没有使用 --headless。")
    return 1

  var output_global := ProjectSettings.globalize_path(output_path)
  DirAccess.make_dir_recursive_absolute(output_global.get_base_dir())
  var save_err := image.save_png(output_global)
  if save_err != OK:
    push_error("保存截图失败: %s err=%s" % [output_path, save_err])
    return 1

  print("saved ", output_global)
  return OK
