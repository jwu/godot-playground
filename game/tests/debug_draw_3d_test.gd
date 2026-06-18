extends GdUnitTestSuite
## DebugDraw3D 场景的单元测试

const DEBUG_DRAW_3D_SCENE := preload("res://scenes/debug_draw_3d.tscn")
const FREE_CAMERA_SCENE := preload("res://entities/free_camera.tscn")


func test_scene_loads() -> void:
  var runner := scene_runner("res://scenes/debug_draw_3d.tscn")
  var scene := runner.scene()
  assert_object(scene).is_not_null()
  assert_str(scene.name).is_equal("DebugDraw3D")


func test_scene_has_required_nodes() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D

  assert_object(scene).is_not_null()
  assert_object(scene.get_node_or_null("FreeCamera")).is_not_null()
  assert_bool(scene.get_node("FreeCamera") is Camera3D).is_true()
  assert_object(scene.get_node_or_null("DrawMesh")).is_not_null()
  assert_object(scene.get_node_or_null("UI")).is_not_null()
  assert_object(scene.get_node_or_null("UI/InfoLabel")).is_not_null()


func test_ready_creates_immediate_mesh_and_redraws_surfaces() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame

  scene.call("_redraw")

  var draw_mesh: MeshInstance3D = scene.get_node_or_null("DrawMesh") as MeshInstance3D
  assert_object(draw_mesh).is_not_null()
  assert_object(draw_mesh.mesh).is_not_null()
  assert_bool(draw_mesh.mesh is ImmediateMesh).is_true()
  assert_int(draw_mesh.mesh.get_surface_count()).is_greater(0)


func test_draw_mesh_uses_vertex_color_unshaded_material() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  var draw_mesh: MeshInstance3D = scene.get_node_or_null("DrawMesh") as MeshInstance3D
  var material: StandardMaterial3D = draw_mesh.material_override as StandardMaterial3D

  assert_object(material).is_not_null()
  assert_bool(material.vertex_color_use_as_albedo).is_true()
  assert_int(material.shading_mode).is_equal(BaseMaterial3D.SHADING_MODE_UNSHADED)
  assert_int(material.transparency).is_equal(BaseMaterial3D.TRANSPARENCY_ALPHA)


func test_scene_includes_endless_grid_entity() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame

  var endless_grid: MeshInstance3D = scene.get_node_or_null("EndlessGrid3D") as MeshInstance3D
  assert_object(endless_grid).is_not_null()
  assert_object(endless_grid.mesh).is_not_null()
  assert_bool(endless_grid.mesh is ArrayMesh).is_true()


func test_free_camera_entity_is_camera() -> void:
  var free_camera: FreeCamera = auto_free(FREE_CAMERA_SCENE.instantiate()) as FreeCamera

  assert_object(free_camera).is_not_null()
  assert_bool(free_camera is Camera3D).is_true()
  assert_object(free_camera.get_camera()).is_same(free_camera)
