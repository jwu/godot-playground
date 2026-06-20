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


func test_line_and_polyline_families_render() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  debug_draw.draw_line(Vector3.ZERO, Vector3.RIGHT, Color.RED)
  debug_draw.draw_polyline(
    PackedVector3Array([Vector3.ZERO, Vector3.UP, Vector3(1.0, 1.0, 0.0)]),
    Color.GREEN,
    DebugDraw3DNode.LineStyle.DASH,
  )
  debug_draw.draw_polyline(
    PackedVector3Array([Vector3(1.0, 0.0, 0.0), Vector3(1.0, 1.0, 0.0)]),
    Color.ORANGE,
  )
  debug_draw.draw_cylinder_line(Vector3(2.0, 0.0, 0.0), Vector3(2.0, 1.0, 0.0), 0.1, Color.BLUE)
  debug_draw.draw_cylinder_polyline(
    PackedVector3Array([Vector3(3.0, 0.0, 0.0), Vector3(3.0, 1.0, 0.0), Vector3(4.0, 1.0, 0.0)]),
    0.1,
    Color.YELLOW,
  )
  await get_tree().process_frame

  assert_int(debug_draw.get_depth_mesh_instance().mesh.get_surface_count()).is_greater(0)


func test_flat_shapes_and_arrow_families_render() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  debug_draw.draw_arrow(Vector3.ZERO, Vector3.RIGHT, Color.RED, DebugDraw3DNode.ArrowPointType.CIRCLE)
  debug_draw.draw_arrow_3d(Vector3(0.0, 1.0, 0.0), Vector3(1.0, 1.0, 0.0), 0.08, Color.GREEN)
  debug_draw.draw_flat_circle(Vector3(0.0, 0.0, 1.0), 0.5, Vector3.UP, Color.BLUE)
  debug_draw.draw_flat_rect(Vector3(1.5, 0.0, 1.0), Vector2.ONE, Vector3.RIGHT, Vector3.FORWARD, Color.YELLOW)
  debug_draw.draw_flat_triangle(Vector3(3.0, 0.0, 1.0), Vector3(4.0, 0.0, 1.0), Vector3(3.5, 0.0, 2.0), Color.MAGENTA)
  await get_tree().process_frame

  assert_int(debug_draw.get_depth_mesh_instance().mesh.get_surface_count()).is_greater(0)


func test_arrow_curve_head_size_matches_arrow_for_same_length() -> void:
  var arrow_width := await _render_arrow_head_width(false)
  var arrow_curve_width := await _render_arrow_head_width(true)

  assert_float(arrow_curve_width).is_equal_approx(arrow_width, 0.001)


func test_arrow_curve_body_reaches_arrow_tip_like_arrow() -> void:
  var vertices := await _render_arrow_curve_line_vertices(DebugDraw3DNode.CurveType.LINES)
  var tip := Vector3.RIGHT * 2.0
  var has_body_segment_to_tip := false
  for i in range(0, vertices.size(), 2):
    if vertices[i + 1].is_equal_approx(tip) and not vertices[i].is_equal_approx(tip):
      has_body_segment_to_tip = true
      break

  assert_bool(has_body_segment_to_tip).is_true()


func test_arrow_curve_head_slants_match_arrow_for_same_length() -> void:
  var arrow_slant := await _render_arrow_head_slant_length(false, DebugDraw3DNode.CurveType.LINES)
  var line_curve_slant := await _render_arrow_head_slant_length(true, DebugDraw3DNode.CurveType.LINES)
  var bezier_curve_slant := await _render_arrow_head_slant_length(true, DebugDraw3DNode.CurveType.BEZIER)

  assert_float(line_curve_slant).is_equal_approx(arrow_slant, 0.001)
  assert_float(bezier_curve_slant).is_equal_approx(arrow_slant, 0.001)


func test_curve_families_render_all_curve_types() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  var points := PackedVector3Array(
    [
      Vector3.ZERO,
      Vector3(0.5, 1.0, 0.0),
      Vector3(1.0, 0.0, 0.0),
      Vector3(1.5, 1.0, 0.0),
    ],
  )
  var curve_types := [
    DebugDraw3DNode.CurveType.BEZIER,
    DebugDraw3DNode.CurveType.ROUND_CORNER,
    DebugDraw3DNode.CurveType.CLOSED_ROUND_CORNER,
    DebugDraw3DNode.CurveType.CATMULL_ROM,
    DebugDraw3DNode.CurveType.LINES,
    DebugDraw3DNode.CurveType.HERMITE,
  ]
  for i in curve_types.size():
    var shifted := PackedVector3Array()
    for point: Vector3 in points:
      shifted.append(point + Vector3(float(i) * 2.0, 0.0, 0.0))
    debug_draw.draw_curve(shifted, Color.CYAN, curve_types[i])
  debug_draw.draw_arrow_curve(points, Color.YELLOW, DebugDraw3DNode.CurveType.BEZIER)
  debug_draw.draw_cylinder_curve(points, 0.08, Color.ORANGE, DebugDraw3DNode.CurveType.CATMULL_ROM)
  debug_draw.draw_cylinder_arrow_curve(points, 0.08, Color.GREEN, DebugDraw3DNode.CurveType.CATMULL_ROM)
  await get_tree().process_frame

  assert_int(debug_draw.get_depth_mesh_instance().mesh.get_surface_count()).is_greater(0)


func test_curve_sampling_follows_jwu_immediate_semantics() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DebugDraw3DNode.new()) as DebugDraw3DNode

  var bezier_points := PackedVector3Array(
    [
      Vector3(0.0, 0.0, 0.0),
      Vector3(1.0, 0.0, 0.0),
      Vector3(2.0, 0.0, 0.0),
      Vector3(3.0, 0.0, 0.0),
      Vector3(4.0, 0.0, 0.0),
      Vector3(5.0, 0.0, 0.0),
      Vector3(6.0, 0.0, 0.0),
    ],
  )
  var bezier: PackedVector3Array = debug_draw.call(
    "_sample_curve",
    bezier_points,
    DebugDraw3DNode.CurveType.BEZIER,
  ) as PackedVector3Array
  assert_int(bezier.size()).is_greater(bezier_points.size())
  assert_float(bezier[bezier.size() - 1].x).is_equal_approx(6.0, 0.001)

  var hermite: PackedVector3Array = debug_draw.call(
    "_sample_curve",
    PackedVector3Array(
      [
        Vector3(0.0, 0.0, 0.0),
        Vector3(1.0, 1.0, 0.0),
        Vector3(2.0, 0.0, 0.0),
        Vector3(3.0, -1.0, 0.0),
      ],
    ),
    DebugDraw3DNode.CurveType.HERMITE,
  ) as PackedVector3Array
  assert_float(hermite[hermite.size() - 1].x).is_equal_approx(2.0, 0.001)


func test_dense_cylinder_curves_keep_immediate_vertex_budget() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  var points := PackedVector3Array(
    [
      Vector3(-20.0, 0.0, 6.0),
      Vector3(-16.0, 4.0, 8.0),
      Vector3(-12.0, 1.0, 12.0),
      Vector3(-8.0, 5.0, 10.0),
    ],
  )
  var arrow_points := points.duplicate()
  arrow_points.append(Vector3(-4.0, 2.0, 12.0))
  debug_draw.draw_cylinder_curve(
    points,
    0.08,
    Color.ORANGE,
    DebugDraw3DNode.CurveType.BEZIER,
    DebugDraw3DNode.MeshType.MIXED,
  )
  debug_draw.draw_cylinder_arrow_curve(
    arrow_points,
    0.08,
    Color.GREEN,
    DebugDraw3DNode.CurveType.CATMULL_ROM,
  )
  await get_tree().process_frame

  var vertex_count := _count_mesh_vertices(debug_draw.get_depth_mesh_instance().mesh)
  assert_int(vertex_count).is_less(80000)


func test_mixed_mesh_uses_translucent_solid_color() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  debug_draw.draw_box(Vector3.ZERO, Vector3.ONE, Color.RED, DebugDraw3DNode.MeshType.MIXED)
  await get_tree().process_frame

  var depth_mesh: Mesh = debug_draw.get_depth_mesh_instance().mesh
  var triangle_arrays: Array = depth_mesh.surface_get_arrays(1)
  var triangle_colors: PackedColorArray = triangle_arrays[Mesh.ARRAY_COLOR]
  assert_float(triangle_colors[0].a).is_equal_approx(0.2, 0.001)


func test_mesh_types_generate_observable_surfaces() -> void:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  debug_draw.draw_box(Vector3.ZERO, Vector3.ONE, Color.RED, DebugDraw3DNode.MeshType.SOLID)
  debug_draw.draw_sphere(Vector3(2.0, 0.0, 0.0), 0.5, Color.GREEN, DebugDraw3DNode.MeshType.WIREFRAME)
  debug_draw.draw_cylinder(Vector3(4.0, 0.0, 0.0), 0.3, 1.0, Color.BLUE, DebugDraw3DNode.MeshType.MIXED)
  debug_draw.draw_capsule(Vector3(6.0, 0.0, 0.0), 0.3, 1.2, Color.YELLOW, DebugDraw3DNode.MeshType.SOLID)
  debug_draw.draw_cone(Vector3(8.0, 0.0, 0.0), 0.4, 1.2, Color.MAGENTA, DebugDraw3DNode.MeshType.WIREFRAME)
  await get_tree().process_frame

  assert_int(debug_draw.get_depth_mesh_instance().mesh.get_surface_count()).is_greater(1)


func _render_arrow_head_width(use_curve: bool) -> float:
  var vertices := PackedVector3Array()
  if use_curve:
    vertices = await _render_arrow_curve_line_vertices(DebugDraw3DNode.CurveType.LINES)
  else:
    vertices = await _render_arrow_line_vertices()
  return vertices[vertices.size() - 3].distance_to(vertices[vertices.size() - 1])


func _render_arrow_head_slant_length(use_curve: bool, curve_type: DebugDraw3DNode.CurveType) -> float:
  var vertices := PackedVector3Array()
  if use_curve:
    vertices = await _render_arrow_curve_line_vertices(curve_type)
  else:
    vertices = await _render_arrow_line_vertices()
  return vertices[vertices.size() - 4].distance_to(vertices[vertices.size() - 3])


func _render_arrow_line_vertices() -> PackedVector3Array:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  debug_draw.draw_arrow(Vector3.ZERO, Vector3.RIGHT * 2.0, Color.RED)
  await get_tree().process_frame

  var arrays := debug_draw.get_depth_mesh_instance().mesh.surface_get_arrays(0)
  return arrays[Mesh.ARRAY_VERTEX]


func _render_arrow_curve_line_vertices(curve_type: DebugDraw3DNode.CurveType) -> PackedVector3Array:
  var debug_draw: DebugDraw3DNode = auto_free(DEBUG_DRAW_3D_SHARED_SCENE.instantiate()) as DebugDraw3DNode
  add_child(debug_draw)
  await get_tree().process_frame

  debug_draw.draw_arrow_curve(
    _make_arrow_curve_points(curve_type),
    Color.RED,
    curve_type,
  )
  await get_tree().process_frame

  var arrays := debug_draw.get_depth_mesh_instance().mesh.surface_get_arrays(0)
  return arrays[Mesh.ARRAY_VERTEX]


func _make_arrow_curve_points(curve_type: DebugDraw3DNode.CurveType) -> PackedVector3Array:
  if curve_type == DebugDraw3DNode.CurveType.LINES:
    return PackedVector3Array([Vector3.ZERO, Vector3.RIGHT * 2.0])
  return PackedVector3Array(
    [
      Vector3.ZERO,
      Vector3(0.5, 1.0, 0.0),
      Vector3(1.5, -1.0, 0.0),
      Vector3.RIGHT * 2.0,
    ],
  )


func _count_mesh_vertices(mesh: Mesh) -> int:
  var vertices := 0
  for surface_index in mesh.get_surface_count():
    var arrays := mesh.surface_get_arrays(surface_index)
    var surface_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    vertices += surface_vertices.size()
  return vertices
