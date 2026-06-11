extends VBoxContainer
## Logger：从下往上显示日志，并根据自身矩形高度自动控制可见条数和透明度。
##
## 调用 log(message) 记录一条日志。最新日志显示在最下方且不透明，越靠上越透明。

@export var max_stored_lines: int = 200
@export var log_font_size: int = 13
@export var log_line_padding: int = 2
@export var log_color: Color = Color(0.86, 0.92, 1.0, 1.0)

var _events: Array[String] = []


func _ready() -> void:
  mouse_filter = Control.MOUSE_FILTER_IGNORE
  alignment = BoxContainer.ALIGNMENT_END
  add_theme_constant_override("separation", 0)

  resized.connect(_update_log_display)
  _update_log_display.call_deferred()


func log(message: String) -> void:
  _events.push_front(message)

  var max_stored_count: int = max(max_stored_lines, _get_visible_log_count())
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

  var visible_count: int = min(_events.size(), _get_visible_log_count())
  if visible_count <= 0:
    return

  # _events[0] 是最新日志。为了让日志从下往上增长，这里按「旧 -> 新」添加节点。
  for event_index: int in range(visible_count - 1, -1, -1):
    var display_index: int = visible_count - 1 - event_index
    var alpha: float = 1.0 if visible_count == 1 else float(display_index) / float(visible_count - 1)

    var log_label := Label.new()
    log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    log_label.text = _events[event_index]
    log_label.modulate = Color(1.0, 1.0, 1.0, alpha)
    log_label.custom_minimum_size.y = _get_log_line_height()
    log_label.add_theme_font_size_override("font_size", log_font_size)
    log_label.add_theme_color_override("font_color", log_color)
    add_child(log_label)


func _get_visible_log_count() -> int:
  var rect_height := get_rect().size.y
  if rect_height <= 0.0:
    return 0

  return max(1, int(floor(rect_height / float(_get_log_line_height()))))


func _get_log_line_height() -> int:
  var font_height := float(log_font_size)
  var font := get_theme_font("font", "Label")
  if font != null:
    font_height = font.get_height(log_font_size)

  return max(1, int(ceil(font_height + log_line_padding)))
