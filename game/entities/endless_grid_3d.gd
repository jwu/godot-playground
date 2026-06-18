extends MeshInstance3D
## EndlessGrid3D：程序化构建的 6 顶点 shader grid。
##
## 只创建两个三角形组成的 XZ 平面，网格线、LOD、渐隐都在 shader 中按像素计算。
## 默认跟随当前 viewport camera 的 XZ 坐标，形成 endless grid 效果。

const GRID_SHADER := preload("res://entities/endless_grid_3d.gdshader")

@export var follow_viewport_camera := true
@export var grid_size := 2000.0
@export var cell_size := 1.0
@export var min_pixels_between_cells := 2.0
@export var line_width_pixels := 2.0
@export var enable_grazing_opacity := true
@export var thin_line_color := Color(0.3, 0.3, 0.3, 0.5)
@export var thick_line_color := Color(0.4, 0.4, 0.4, 0.7)

var _shader_material: ShaderMaterial


func _ready() -> void:
  _rebuild_mesh()
  _ensure_shader_material()
  _apply_shader_parameters()


func _process(_delta: float) -> void:
  if not follow_viewport_camera:
    return

  var camera := get_viewport().get_camera_3d()
  if camera == null:
    return

  follow_camera(camera)


func follow_camera(camera: Camera3D) -> void:
  global_position = Vector3(camera.global_position.x, 0.0, camera.global_position.z)


func set_grid_size(value: float) -> void:
  grid_size = maxf(value, 1.0)
  _rebuild_mesh()
  _apply_shader_parameters()


func set_cell_size(value: float) -> void:
  cell_size = maxf(value, 0.0001)
  _apply_shader_parameters()


func _rebuild_mesh() -> void:
  var half := maxf(grid_size, 1.0) * 0.5
  var vertices := PackedVector3Array(
    [
      Vector3(-half, 0.0, -half),
      Vector3(half, 0.0, -half),
      Vector3(half, 0.0, half),
      Vector3(-half, 0.0, -half),
      Vector3(half, 0.0, half),
      Vector3(-half, 0.0, half),
    ],
  )

  var arrays := []
  arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX] = vertices

  var array_mesh := ArrayMesh.new()
  array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
  mesh = array_mesh


func _ensure_shader_material() -> void:
  _shader_material = material_override as ShaderMaterial
  if _shader_material != null:
    return

  _shader_material = ShaderMaterial.new()
  _shader_material.shader = GRID_SHADER
  material_override = _shader_material


func _apply_shader_parameters() -> void:
  if _shader_material == null:
    return

  _shader_material.set_shader_parameter("grid_size", grid_size)
  _shader_material.set_shader_parameter("cell_size", cell_size)
  _shader_material.set_shader_parameter("min_pixels_between_cells", min_pixels_between_cells)
  _shader_material.set_shader_parameter("line_width_pixels", line_width_pixels)
  _shader_material.set_shader_parameter("enable_grazing_opacity", enable_grazing_opacity)
  _shader_material.set_shader_parameter("thin_line_color", thin_line_color)
  _shader_material.set_shader_parameter("thick_line_color", thick_line_color)
