extends GdUnitTestSuite
## DebugDraw3D 场景的基础设施测试

const DebugDraw3DNode := preload("res://shared/debug_draw_3d/debug_draw_3d.gd")
const DEBUG_DRAW_3D_SCENE := preload("res://scenes/debug_draw_3d.tscn")


func test_scene_loads() -> void:
  var runner := scene_runner("res://scenes/debug_draw_3d.tscn")
  var scene := runner.scene()
  assert_object(scene).is_not_null()
  assert_str(scene.name).is_equal("DebugDraw3D")


func test_scene_has_required_infrastructure_nodes() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D

  assert_object(scene).is_not_null()
  assert_object(scene.get_node_or_null("FreeCamera")).is_not_null()
  assert_bool(scene.get_node("FreeCamera") is Camera3D).is_true()
  assert_object(scene.get_node_or_null("EndlessGrid3D")).is_not_null()
  assert_object(scene.get_node_or_null("DebugDraw3D")).is_not_null()
  assert_bool(scene.get_node("DebugDraw3D") is DebugDraw3DNode).is_true()
  assert_object(scene.get_node_or_null("UI")).is_not_null()
  assert_object(scene.get_node_or_null("UI/InfoLabel")).is_not_null()


func test_ready_draws_draw_line_demo_surfaces() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame
  await get_tree().process_frame

  var debug_draw: DebugDraw3DNode = scene.get_node_or_null("DebugDraw3D") as DebugDraw3DNode
  assert_object(debug_draw).is_not_null()
  assert_object(debug_draw.get_depth_mesh_instance().mesh).is_not_null()
  assert_bool(debug_draw.get_depth_mesh_instance().mesh is ImmediateMesh).is_true()
  assert_int(debug_draw.get_depth_mesh_instance().mesh.get_surface_count()).is_greater(0)
  assert_int(debug_draw.get_overhead_mesh_instance().mesh.get_surface_count()).is_greater(0)


func test_ready_creates_origin_axes_labels() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame

  var x_label: Label3D = scene.get_node_or_null("OriginAxesLabels/XAxisLabel") as Label3D
  var y_label: Label3D = scene.get_node_or_null("OriginAxesLabels/YAxisLabel") as Label3D
  var z_label: Label3D = scene.get_node_or_null("OriginAxesLabels/ZAxisLabel") as Label3D
  assert_object(x_label).is_not_null()
  assert_object(y_label).is_not_null()
  assert_object(z_label).is_not_null()
  assert_str(x_label.text).is_equal("X")
  assert_str(y_label.text).is_equal("Y")
  assert_str(z_label.text).is_equal("Z")
  assert_bool(x_label.no_depth_test).is_false()


func test_ready_creates_reusable_draw_line_labels() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame

  var title_label: Label3D = scene.get_node_or_null("DrawLineLabels/DrawLineTitle") as Label3D
  var dash_label: Label3D = scene.get_node_or_null("DrawLineLabels/DrawLineDashLabel") as Label3D
  var dot_label: Label3D = scene.get_node_or_null("DrawLineLabels/DrawLineDotLabel") as Label3D
  var overhead_label: Label3D = scene.get_node_or_null("DrawLineLabels/DrawLineOverheadLabel") as Label3D
  assert_object(title_label).is_not_null()
  assert_object(dash_label).is_not_null()
  assert_object(dot_label).is_not_null()
  assert_object(overhead_label).is_not_null()
  assert_str(title_label.text).contains("draw_line")
  assert_str(dash_label.text).contains("DASH")
  assert_str(dot_label.text).contains("DOT")
  assert_str(overhead_label.text).contains("overhead=true")
  assert_bool(title_label.fixed_size).is_false()
  assert_bool(title_label.no_depth_test).is_false()
  assert_int(title_label.font_size).is_equal(18)
  assert_float(title_label.pixel_size).is_equal_approx(0.008, 0.0001)
  assert_int(dash_label.horizontal_alignment).is_equal(HORIZONTAL_ALIGNMENT_RIGHT)
  assert_vector(title_label.position).is_equal(Vector3(0.9, 0.1, -0.5))
  assert_vector(dash_label.position).is_equal(Vector3(0.9, 0.1, -2.0))

  var title_instance_id := title_label.get_instance_id()
  await get_tree().process_frame
  var same_title_label: Label3D = scene.get_node_or_null("DrawLineLabels/DrawLineTitle") as Label3D
  assert_int(same_title_label.get_instance_id()).is_equal(title_instance_id)


func test_ui_info_keeps_camera_state_without_operation_help() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame

  var info_label: Label = scene.get_node_or_null("UI/InfoLabel") as Label
  assert_object(info_label).is_not_null()
  assert_str(info_label.text).contains("Dist:")
  assert_str(info_label.text).contains("Speed:")
  assert_str(info_label.text).not_contains("基础操作")
  assert_str(info_label.text).not_contains("中键")
  assert_str(info_label.text).not_contains("Esc")


func test_shared_debug_draw_uses_vertex_color_unshaded_materials() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame

  var debug_draw: DebugDraw3DNode = scene.get_node_or_null("DebugDraw3D") as DebugDraw3DNode
  var material: StandardMaterial3D = debug_draw.get_depth_mesh_instance().material_override as StandardMaterial3D
  var overhead_material: StandardMaterial3D = debug_draw.get_overhead_mesh_instance().material_override as StandardMaterial3D

  assert_object(material).is_not_null()
  assert_bool(material.vertex_color_use_as_albedo).is_true()
  assert_int(material.shading_mode).is_equal(BaseMaterial3D.SHADING_MODE_UNSHADED)
  assert_int(material.transparency).is_equal(BaseMaterial3D.TRANSPARENCY_ALPHA)
  assert_bool(material.no_depth_test).is_false()
  assert_bool(overhead_material.no_depth_test).is_true()


func test_scene_includes_endless_grid_entity() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame

  var endless_grid: MeshInstance3D = scene.get_node_or_null("EndlessGrid3D") as MeshInstance3D
  assert_object(endless_grid).is_not_null()
  assert_object(endless_grid.mesh).is_not_null()
  assert_bool(endless_grid.mesh is ArrayMesh).is_true()
