extends GdUnitTestSuite
## DebugDraw3D 场景的单元测试

const DebugDraw3DNode := preload("res://shared/debug_draw_3d/debug_draw_3d.gd")
const DEBUG_DRAW_3D_SCENE := preload("res://scenes/debug_draw_3d.tscn")


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
  assert_object(scene.get_node_or_null("DebugDraw3D")).is_not_null()
  assert_bool(scene.get_node("DebugDraw3D") is DebugDraw3DNode).is_true()
  assert_object(scene.get_node_or_null("UI")).is_not_null()
  assert_object(scene.get_node_or_null("UI/InfoLabel")).is_not_null()


func test_ready_uses_shared_debug_draw_node_and_redraws_surfaces() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame
  await get_tree().process_frame

  var debug_draw: DebugDraw3DNode = scene.get_node_or_null("DebugDraw3D") as DebugDraw3DNode
  assert_object(debug_draw).is_not_null()
  assert_object(debug_draw.get_depth_mesh_instance().mesh).is_not_null()
  assert_bool(debug_draw.get_depth_mesh_instance().mesh is ImmediateMesh).is_true()
  assert_int(debug_draw.get_depth_mesh_instance().mesh.get_surface_count()).is_greater(0)


func test_ready_creates_reusable_section_labels_as_depth_tested_3d_signs() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame

  var labels_root: Node = scene.get_node_or_null("SpatialLabels")
  assert_object(labels_root).is_not_null()
  assert_int(labels_root.get_child_count()).is_equal(6)

  var title_label: Label3D = scene.get_node_or_null("SpatialLabels/ApiCoverageTitle") as Label3D
  assert_object(title_label).is_not_null()
  assert_str(title_label.text).contains("API 覆盖样例")
  assert_int(title_label.billboard).is_equal(BaseMaterial3D.BILLBOARD_DISABLED)
  assert_bool(title_label.fixed_size).is_false()
  assert_bool(title_label.no_depth_test).is_false()
  assert_bool(is_equal_approx(absf(title_label.global_basis.z.y), 0.0)).is_true()

  var title_instance_id := title_label.get_instance_id()
  await get_tree().process_frame
  var same_title_label: Label3D = scene.get_node_or_null("SpatialLabels/ApiCoverageTitle") as Label3D
  assert_object(same_title_label).is_not_null()
  assert_int(same_title_label.get_instance_id()).is_equal(title_instance_id)


func test_section_labels_cover_major_demo_areas() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame

  var line_label: Label3D = scene.get_node_or_null("SpatialLabels/LinesTitle") as Label3D
  var curve_label: Label3D = scene.get_node_or_null("SpatialLabels/CurvesTitle") as Label3D
  var arrow_label: Label3D = scene.get_node_or_null("SpatialLabels/ArrowsTitle") as Label3D
  var shape_label: Label3D = scene.get_node_or_null("SpatialLabels/ShapesTitle") as Label3D
  var behavior_label: Label3D = scene.get_node_or_null("SpatialLabels/BehaviorTitle") as Label3D
  assert_object(line_label).is_not_null()
  assert_object(curve_label).is_not_null()
  assert_object(arrow_label).is_not_null()
  assert_object(shape_label).is_not_null()
  assert_object(behavior_label).is_not_null()

  assert_str(line_label.text).contains("线段")
  assert_str(curve_label.text).contains("曲线")
  assert_str(arrow_label.text).contains("箭头")
  assert_str(shape_label.text).contains("形状")
  assert_str(behavior_label.text).contains("Layer")


func test_layer_key_toggle_changes_visible_layers_and_ui() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame

  var debug_draw: DebugDraw3DNode = scene.get_node_or_null("DebugDraw3D") as DebugDraw3DNode
  var info_label: Label = scene.get_node_or_null("UI/InfoLabel") as Label
  assert_object(debug_draw).is_not_null()
  assert_object(info_label).is_not_null()
  assert_int(debug_draw.visible_layers).is_equal(7)
  assert_str(info_label.text).contains("Layer: 1=ON 2=ON 3=ON")

  var key_event := InputEventKey.new()
  key_event.keycode = KEY_2
  key_event.physical_keycode = KEY_2
  key_event.pressed = true
  Input.parse_input_event(key_event)
  await get_tree().process_frame

  assert_int(debug_draw.visible_layers).is_equal(5)
  assert_str(info_label.text).contains("Layer: 1=ON 2=OFF 3=ON")


func test_ui_info_keeps_camera_state_and_adds_operation_help() -> void:
  var scene: Node3D = auto_free(DEBUG_DRAW_3D_SCENE.instantiate()) as Node3D
  add_child(scene)
  await get_tree().process_frame

  var info_label: Label = scene.get_node_or_null("UI/InfoLabel") as Label
  assert_object(info_label).is_not_null()
  assert_str(info_label.text).contains("DebugDraw3D API 覆盖样例")
  assert_str(info_label.text).contains("基础操作")
  assert_str(info_label.text).contains("Dist:")


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
