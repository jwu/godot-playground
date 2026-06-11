extends GdUnitTestSuite
## DebugDraw2D 场景的单元测试


func test_scene_loads() -> void:
  var runner := scene_runner("res://scenes/debug_draw_2d.tscn")
  var scene := runner.scene()
  assert_object(scene).is_not_null()
  assert_str(scene.name).is_equal("DebugDraw2D")
