extends GdUnitTestSuite
## EndlessGrid3D 实体的单元测试

const ENDLESS_GRID_3D_SCENE := preload("res://entities/endless_grid_3d.tscn")


func test_scene_builds_six_vertex_array_mesh() -> void:
  var grid: MeshInstance3D = auto_free(ENDLESS_GRID_3D_SCENE.instantiate()) as MeshInstance3D
  add_child(grid)
  await get_tree().process_frame

  assert_object(grid.mesh).is_not_null()
  assert_bool(grid.mesh is ArrayMesh).is_true()
  assert_int(grid.mesh.get_surface_count()).is_equal(1)

  var arrays := grid.mesh.surface_get_arrays(0)
  var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
  assert_int(vertices.size()).is_equal(6)


func test_scene_creates_shader_material() -> void:
  var grid: MeshInstance3D = auto_free(ENDLESS_GRID_3D_SCENE.instantiate()) as MeshInstance3D
  add_child(grid)
  await get_tree().process_frame

  var material: ShaderMaterial = grid.material_override as ShaderMaterial
  assert_object(material).is_not_null()
  assert_object(material.shader).is_not_null()
  assert_float(float(material.get_shader_parameter("grid_size"))).is_greater(0.0)
  assert_float(float(material.get_shader_parameter("cell_size"))).is_greater(0.0)
  assert_bool(bool(material.get_shader_parameter("enable_grazing_opacity"))).is_true()


func test_follow_camera_locks_grid_to_camera_xz() -> void:
  var grid: Node3D = auto_free(ENDLESS_GRID_3D_SCENE.instantiate()) as Node3D
  var camera := Camera3D.new()
  add_child(grid)
  add_child(camera)
  camera.global_position = Vector3(12.0, 8.0, -34.0)
  await get_tree().process_frame

  grid.call("follow_camera", camera)

  assert_float(grid.global_position.x).is_equal_approx(camera.global_position.x, 0.001)
  assert_float(grid.global_position.y).is_equal_approx(0.0, 0.001)
  assert_float(grid.global_position.z).is_equal_approx(camera.global_position.z, 0.001)

  camera.queue_free()
