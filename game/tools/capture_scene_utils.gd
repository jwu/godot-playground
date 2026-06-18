extends RefCounted
## 场景截图工具的通用辅助函数。


static func apply_set_expressions(scene: Node, expressions: Array[String]) -> bool:
  var ok := true
  for expression in expressions:
    if not apply_set_expression(scene, expression):
      ok = false
  return ok


static func apply_set_expression(scene: Node, expression: String) -> bool:
  var equal_index := expression.find("=")
  if equal_index <= 0:
    push_error("--set 格式错误，期望 NodePath.property=value，实际: %s" % expression)
    return false

  var target := expression.substr(0, equal_index).strip_edges()
  var value_text := expression.substr(equal_index + 1).strip_edges()
  var dot_index := target.rfind(".")
  if dot_index <= 0 or dot_index >= target.length() - 1:
    push_error("--set 目标格式错误，期望 NodePath.property，实际: %s" % target)
    return false

  var node_path := target.substr(0, dot_index)
  var property_name := target.substr(dot_index + 1)
  var node := scene.get_node_or_null(NodePath(node_path))
  if node == null:
    push_error("找不到 --set 节点: %s" % node_path)
    return false

  node.set(property_name, parse_value(value_text))
  return true


static func parse_value(text: String) -> Variant:
  var value := text.strip_edges()
  var lower := value.to_lower()

  if lower == "true":
    return true
  if lower == "false":
    return false
  if lower == "null":
    return null

  if (value.begins_with("\"") and value.ends_with("\"")) or (value.begins_with("'") and value.ends_with("'")):
    return value.substr(1, value.length() - 2)

  if lower.begins_with("deg:"):
    return deg_to_rad(float(value.substr(4)))
  if lower.ends_with("deg"):
    return deg_to_rad(float(value.substr(0, value.length() - 3)))

  if lower.begins_with("vector2(") and value.ends_with(")"):
    var parts := _parse_tuple(value.substr(8, value.length() - 9))
    if parts.size() >= 2:
      return Vector2(float(parts[0]), float(parts[1]))

  if lower.begins_with("vector3(") and value.ends_with(")"):
    var parts := _parse_tuple(value.substr(8, value.length() - 9))
    if parts.size() >= 3:
      return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))

  if lower.begins_with("color(") and value.ends_with(")"):
    var parts := _parse_tuple(value.substr(6, value.length() - 7))
    if parts.size() >= 3:
      var alpha := float(parts[3]) if parts.size() >= 4 else 1.0
      return Color(float(parts[0]), float(parts[1]), float(parts[2]), alpha)

  if value.begins_with("(") and value.ends_with(")"):
    var parts := _parse_tuple(value.substr(1, value.length() - 2))
    if parts.size() == 2:
      return Vector2(float(parts[0]), float(parts[1]))
    if parts.size() == 3:
      return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
    if parts.size() == 4:
      return Color(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]))

  if value.is_valid_int():
    return int(value)
  if value.is_valid_float():
    return float(value)

  return value


static func ensure_output_parent(output_path: String) -> void:
  var global_path := ProjectSettings.globalize_path(output_path)
  DirAccess.make_dir_recursive_absolute(global_path.get_base_dir())


static func global_output_path(output_path: String) -> String:
  return ProjectSettings.globalize_path(output_path)


static func _parse_tuple(text: String) -> PackedStringArray:
  var result := PackedStringArray()
  for part in text.split(",", false):
    result.append(part.strip_edges())
  return result
