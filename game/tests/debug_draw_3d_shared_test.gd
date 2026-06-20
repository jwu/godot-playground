extends GdUnitTestSuite
## 共享 DebugDraw3D 节点的行为测试

const DebugDraw3DNode := preload("res://shared/debug_draw_3d/debug_draw_3d.gd")
const DEBUG_DRAW_3D_SHARED_SCENE := preload("res://shared/debug_draw_3d/debug_draw_3d.tscn")


func test_draw_line_flushes_visible_mesh_for_one_frame() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  debug_draw.draw_line(Vector3.ZERO, Vector3.RIGHT, Color.RED)
  await get_tree().process_frame

  var depth_mesh: Mesh = debug_draw.get_depth_mesh_instance().mesh
  assert_int(depth_mesh.get_surface_count()).is_greater(0)

  await get_tree().process_frame

  assert_int(depth_mesh.get_surface_count()).is_equal(0)


func test_debug_visible_blocks_new_geometry() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  debug_draw.debug_visible = false
  debug_draw.draw_line(Vector3.ZERO, Vector3.RIGHT, Color.RED)
  await get_tree().process_frame

  assert_int(debug_draw.get_depth_mesh_instance().mesh.get_surface_count()).is_equal(0)


func test_layer_filter_blocks_disabled_layer() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  debug_draw.set_layer_enabled(DebugDraw3DNode.DEFAULT_LAYER, false)
  debug_draw.draw_line(Vector3.ZERO, Vector3.RIGHT, Color.RED)
  await get_tree().process_frame

  assert_int(debug_draw.get_depth_mesh_instance().mesh.get_surface_count()).is_equal(0)


func test_overhead_draw_uses_no_depth_mesh() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  debug_draw.draw_line(Vector3.ZERO, Vector3.RIGHT, Color.RED, DebugDraw3DNode.LineStyle.DEFAULT, true)
  await get_tree().process_frame

  var overhead_mesh_instance: MeshInstance3D = debug_draw.get_overhead_mesh_instance()
  var material: StandardMaterial3D = overhead_mesh_instance.material_override as StandardMaterial3D
  assert_int(debug_draw.get_depth_mesh_instance().mesh.get_surface_count()).is_equal(0)
  assert_int(overhead_mesh_instance.mesh.get_surface_count()).is_greater(0)
  assert_bool(material.no_depth_test).is_true()


func test_mesh_types_generate_observable_surfaces() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  debug_draw.draw_box(Vector3.ZERO, Vector3.ONE, Color.RED, DebugDraw3DNode.MeshType.SOLID)
  debug_draw.draw_sphere(Vector3(2.0, 0.0, 0.0), 0.5, Color.GREEN, DebugDraw3DNode.MeshType.WIREFRAME)
  debug_draw.draw_cylinder(Vector3(4.0, 0.0, 0.0), 0.3, 1.0, Color.BLUE, DebugDraw3DNode.MeshType.MIXED)
  await get_tree().process_frame

  assert_int(debug_draw.get_depth_mesh_instance().mesh.get_surface_count()).is_greater(1)
