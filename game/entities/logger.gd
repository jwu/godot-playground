extends Control
## Logger：在固定矩形内从下往上显示日志。
##
## 调用 log(message) 记录一条日志。文字会被 Logger 自身矩形裁剪；
## 最新日志显示在最下方且不透明，越靠近矩形顶部越透明。

@export var max_stored_lines: int = 200
@export var log_font_size: int = 13
@export var log_line_padding: int = 2
@export var log_color: Color = Color(0.86, 0.92, 1.0, 1.0)

var _events: Array[String] = []


func _ready() -> void:
  mouse_filter = Control.MOUSE_FILTER_IGNORE
  clip_contents = true

  resized.connect(_update_log_display)
  _update_log_display.call_deferred()


func log(message: String) -> void:
  _events.push_front(message)

  var max_stored_count: int = max(max_stored_lines, _get_render_log_count())
  if _events.size() > max_stored_count:
    _events.resize(max_stored_count)

  _update_log_display()


func clear() -> void:
  _events.clear()
  _update_log_display()


func _update_log_display() -> void:
  for child in get_children():
    remove_child(child)
    child.queue_free()

  var render_count: int = min(_events.size(), _get_render_log_count())
  if render_count <= 0:
    return

  var rect_size := size
  var line_height := float(_get_log_line_height())

  # _events[0] 是最新日志。这里按「旧 -> 新」添加节点，使最新日志位于底部。
  # 节点使用绝对位置，不参与 Container 布局，避免文字数量反过来撑大 Logger 矩形。
  for event_index: int in range(render_count - 1, -1, -1):
    var display_index: int = render_count - 1 - event_index
    var y := rect_size.y - float(render_count - display_index) * line_height
    var alpha := clampf((y + line_height) / maxf(rect_size.y, 1.0), 0.0, 1.0)

    var log_label := Label.new()
    log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    log_label.clip_text = true
    log_label.text = _events[event_index]
    log_label.position = Vector2(0.0, y)
    log_label.size = Vector2(rect_size.x, line_height)
    log_label.modulate = Color(1.0, 1.0, 1.0, alpha)
    log_label.add_theme_font_size_override("font_size", log_font_size)
    log_label.add_theme_color_override("font_color", log_color)
    add_child(log_label)


func _get_render_log_count() -> int:
  var rect_height := size.y
  if rect_height <= 0.0:
    return 0

  # 使用 ceil 多渲染顶部可能被截断的一行，让 clip_contents 负责裁剪。
  return max(1, int(ceil(rect_height / float(_get_log_line_height()))))


func _get_log_line_height() -> int:
  var font_height := float(log_font_size)
  var font := get_theme_font("font", "Label")
  if font != null:
    font_height = font.get_height(log_font_size)

  return max(1, int(ceil(font_height + log_line_padding)))
