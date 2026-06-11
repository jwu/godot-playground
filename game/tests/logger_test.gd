extends GdUnitTestSuite
## Logger 实体的单元测试

const LOGGER_SCENE := preload("res://entities/logger.tscn")
const LoggerEntity := preload("res://entities/logger.gd")


func test_scene_has_editor_placeholder_before_ready() -> void:
  var logger: LoggerEntity = auto_free(LOGGER_SCENE.instantiate()) as LoggerEntity

  assert_str(logger.name).is_equal("Logger")
  assert_object(logger.get_node_or_null("EditorPlaceholder")).is_not_null()


func test_log_records_messages_from_bottom_to_top() -> void:
  var logger: LoggerEntity = auto_free(LOGGER_SCENE.instantiate()) as LoggerEntity
  add_child(logger)
  logger.size = Vector2(360, 120)
  await get_tree().process_frame

  logger.log("first")
  logger.log("second")

  assert_int(logger.get_child_count()).is_equal(2)
  assert_str((logger.get_child(0) as Label).text).is_equal("first")
  assert_str((logger.get_child(1) as Label).text).is_equal("second")


func test_log_count_and_alpha_follow_rect_height() -> void:
  var logger: LoggerEntity = auto_free(LOGGER_SCENE.instantiate()) as LoggerEntity
  add_child(logger)
  logger.size = Vector2(360, 45)
  logger.log_font_size = 13
  logger.log_line_padding = 2
  await get_tree().process_frame

  for index: int in range(10):
    logger.log("line-%d" % index)

  var expected_count: int = int(logger.call("_get_visible_log_count"))
  assert_int(logger.get_child_count()).is_equal(expected_count)

  if expected_count > 1:
    assert_float((logger.get_child(0) as Label).modulate.a).is_equal_approx(0.0, 0.001)
  assert_float((logger.get_child(logger.get_child_count() - 1) as Label).modulate.a).is_equal_approx(1.0, 0.001)


func test_clear_removes_logs() -> void:
  var logger: LoggerEntity = auto_free(LOGGER_SCENE.instantiate()) as LoggerEntity
  add_child(logger)
  logger.size = Vector2(360, 120)
  await get_tree().process_frame

  logger.log("message")
  assert_int(logger.get_child_count()).is_equal(1)

  logger.clear()
  assert_int(logger.get_child_count()).is_equal(0)
