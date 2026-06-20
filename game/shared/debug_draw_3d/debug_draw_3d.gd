class_name DebugDraw3D
extends Node3D
## 场景内 immediate 3D 调试绘制节点。
##
## 调用方在本帧提交 draw_* 命令；本节点用较晚 process priority 自动 flush，
## 下一帧没有新命令时会清空几何。
## layer 参数使用位标记：1、2、4、8……，与 visible_layers 做按位过滤。

enum MeshType {
  SOLID,
  WIREFRAME,
  MIXED,
}
enum LineStyle {
  DEFAULT,
  DASH,
  DOT,
}
enum CurveType {
  BEZIER,
  ROUND_CORNER,
  CLOSED_ROUND_CORNER,
  CATMULL_ROM,
  LINES,
  HERMITE,
}
enum ArrowPointType {
  NONE,
  TRIANGLE,
  PRISMATIC,
  CIRCLE,
}

const DEFAULT_LAYER := 1
const DEFAULT_PROCESS_PRIORITY := 100000
const SEGMENTS_CIRCLE := 32
const SEGMENTS_CURVE := 12
const DASH_LENGTH := 0.45
const DASH_GAP := 0.25
const DOT_LENGTH := 0.08
const DOT_GAP := 0.22

@export var debug_visible := true
@export_flags_3d_render var visible_layers := DEFAULT_LAYER

var _commands: Array[Dictionary] = []
var _depth_line_vertices: Array[Vector3] = []
var _depth_line_colors: Array[Color] = []
var _depth_triangle_vertices: Array[Vector3] = []
var _depth_triangle_colors: Array[Color] = []
var _overhead_line_vertices: Array[Vector3] = []
var _overhead_line_colors: Array[Color] = []
var _overhead_triangle_vertices: Array[Vector3] = []
var _overhead_triangle_colors: Array[Color] = []

@onready var _depth_mesh_instance: MeshInstance3D = $DepthMesh
@onready var _overhead_mesh_instance: MeshInstance3D = $OverheadMesh


func _ready() -> void:
  process_priority = DEFAULT_PROCESS_PRIORITY
  _ensure_mesh_instance(_depth_mesh_instance, false)
  _ensure_mesh_instance(_overhead_mesh_instance, true)


func _process(_delta: float) -> void:
  flush()


func flush() -> void:
  _clear_meshes()
  _reset_buffers()

  if debug_visible:
    for command: Dictionary in _commands:
      if _is_layer_visible(int(command["layer"])):
        _emit_command(command)

  _commit_mesh(
    _depth_mesh_instance.mesh as ImmediateMesh,
    _depth_line_vertices,
    _depth_line_colors,
    _depth_triangle_vertices,
    _depth_triangle_colors,
  )
  _commit_mesh(
    _overhead_mesh_instance.mesh as ImmediateMesh,
    _overhead_line_vertices,
    _overhead_line_colors,
    _overhead_triangle_vertices,
    _overhead_triangle_colors,
  )
  _commands.clear()


func set_layer_enabled(layer: int, enabled: bool) -> void:
  if layer <= 0:
    return
  if enabled:
    visible_layers |= layer
  else:
    visible_layers &= ~layer


func get_depth_mesh_instance() -> MeshInstance3D:
  return _depth_mesh_instance


func get_overhead_mesh_instance() -> MeshInstance3D:
  return _overhead_mesh_instance


func draw_line(
    from: Vector3,
    to: Vector3,
    color: Color = Color.WHITE,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "line",
      "from": from,
      "to": to,
      "color": color,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_polyline(
    points: PackedVector3Array,
    color: Color = Color.WHITE,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "polyline",
      "points": points,
      "color": color,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_curve(
    points: PackedVector3Array,
    color: Color = Color.WHITE,
    curve_type: CurveType = CurveType.CATMULL_ROM,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "curve",
      "points": points,
      "color": color,
      "curve_type": curve_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_arrow(
    from: Vector3,
    to: Vector3,
    color: Color = Color.WHITE,
    point_type: ArrowPointType = ArrowPointType.TRIANGLE,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "arrow",
      "from": from,
      "to": to,
      "color": color,
      "point_type": point_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_arrow_curve(
    points: PackedVector3Array,
    color: Color = Color.WHITE,
    curve_type: CurveType = CurveType.CATMULL_ROM,
    point_type: ArrowPointType = ArrowPointType.TRIANGLE,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "arrow_curve",
      "points": points,
      "color": color,
      "curve_type": curve_type,
      "point_type": point_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_flat_circle(
    center: Vector3,
    radius: float,
    normal: Vector3,
    color: Color = Color.WHITE,
    mesh_type: MeshType = MeshType.WIREFRAME,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "flat_circle",
      "center": center,
      "radius": radius,
      "normal": normal,
      "color": color,
      "mesh_type": mesh_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_flat_rect(
    center: Vector3,
    size: Vector2,
    axis_u: Vector3,
    axis_v: Vector3,
    color: Color = Color.WHITE,
    mesh_type: MeshType = MeshType.WIREFRAME,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "flat_rect",
      "center": center,
      "size": size,
      "axis_u": axis_u,
      "axis_v": axis_v,
      "color": color,
      "mesh_type": mesh_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_flat_triangle(
    a: Vector3,
    b: Vector3,
    c: Vector3,
    color: Color = Color.WHITE,
    mesh_type: MeshType = MeshType.WIREFRAME,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "flat_triangle",
      "a": a,
      "b": b,
      "c": c,
      "color": color,
      "mesh_type": mesh_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_cylinder_line(
    from: Vector3,
    to: Vector3,
    radius: float,
    color: Color = Color.WHITE,
    mesh_type: MeshType = MeshType.WIREFRAME,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "cylinder_line",
      "from": from,
      "to": to,
      "radius": radius,
      "color": color,
      "mesh_type": mesh_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_cylinder_polyline(
    points: PackedVector3Array,
    radius: float,
    color: Color = Color.WHITE,
    mesh_type: MeshType = MeshType.WIREFRAME,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "cylinder_polyline",
      "points": points,
      "radius": radius,
      "color": color,
      "mesh_type": mesh_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_cylinder_curve(
    points: PackedVector3Array,
    radius: float,
    color: Color = Color.WHITE,
    curve_type: CurveType = CurveType.CATMULL_ROM,
    mesh_type: MeshType = MeshType.WIREFRAME,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "cylinder_curve",
      "points": points,
      "radius": radius,
      "color": color,
      "curve_type": curve_type,
      "mesh_type": mesh_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_3d_arrow(
    from: Vector3,
    to: Vector3,
    radius: float,
    color: Color = Color.WHITE,
    point_type: ArrowPointType = ArrowPointType.PRISMATIC,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "arrow_3d",
      "from": from,
      "to": to,
      "radius": radius,
      "color": color,
      "point_type": point_type,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_arrow_3d(
    from: Vector3,
    to: Vector3,
    radius: float,
    color: Color = Color.WHITE,
    point_type: ArrowPointType = ArrowPointType.PRISMATIC,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  draw_3d_arrow(from, to, radius, color, point_type, overhead, layer)


func draw_box(
    center: Vector3,
    size: Vector3,
    color: Color = Color.WHITE,
    mesh_type: MeshType = MeshType.WIREFRAME,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "box",
      "center": center,
      "size": size,
      "color": color,
      "mesh_type": mesh_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_sphere(
    center: Vector3,
    radius: float,
    color: Color = Color.WHITE,
    mesh_type: MeshType = MeshType.WIREFRAME,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "sphere",
      "center": center,
      "radius": radius,
      "color": color,
      "mesh_type": mesh_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_cylinder(
    center: Vector3,
    radius: float,
    height: float,
    color: Color = Color.WHITE,
    mesh_type: MeshType = MeshType.WIREFRAME,
    axis: Vector3 = Vector3.UP,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "cylinder",
      "center": center,
      "radius": radius,
      "height": height,
      "axis": axis,
      "color": color,
      "mesh_type": mesh_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_capsule(
    center: Vector3,
    radius: float,
    height: float,
    color: Color = Color.WHITE,
    mesh_type: MeshType = MeshType.WIREFRAME,
    axis: Vector3 = Vector3.UP,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "capsule",
      "center": center,
      "radius": radius,
      "height": height,
      "axis": axis,
      "color": color,
      "mesh_type": mesh_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func draw_cone(
    center: Vector3,
    radius: float,
    height: float,
    color: Color = Color.WHITE,
    mesh_type: MeshType = MeshType.WIREFRAME,
    axis: Vector3 = Vector3.UP,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "cone",
      "center": center,
      "radius": radius,
      "height": height,
      "axis": axis,
      "color": color,
      "mesh_type": mesh_type,
      "style": style,
      "overhead": overhead,
      "layer": layer,
    },
  )


func _ensure_mesh_instance(mesh_instance: MeshInstance3D, no_depth_test: bool) -> void:
  mesh_instance.mesh = ImmediateMesh.new()
  var material := StandardMaterial3D.new()
  material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  material.vertex_color_use_as_albedo = true
  material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  material.cull_mode = BaseMaterial3D.CULL_DISABLED
  material.no_depth_test = no_depth_test
  mesh_instance.material_override = material


func _clear_meshes() -> void:
  (_depth_mesh_instance.mesh as ImmediateMesh).clear_surfaces()
  (_overhead_mesh_instance.mesh as ImmediateMesh).clear_surfaces()


func _reset_buffers() -> void:
  _depth_line_vertices.clear()
  _depth_line_colors.clear()
  _depth_triangle_vertices.clear()
  _depth_triangle_colors.clear()
  _overhead_line_vertices.clear()
  _overhead_line_colors.clear()
  _overhead_triangle_vertices.clear()
  _overhead_triangle_colors.clear()


func _is_layer_visible(layer: int) -> bool:
  return layer > 0 and (visible_layers & layer) != 0


func _commit_mesh(
    mesh: ImmediateMesh,
    line_vertices: Array[Vector3],
    line_colors: Array[Color],
    triangle_vertices: Array[Vector3],
    triangle_colors: Array[Color],
) -> void:
  if line_vertices.size() > 0:
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    for i in line_vertices.size():
      mesh.surface_set_color(line_colors[i])
      mesh.surface_add_vertex(line_vertices[i])
    mesh.surface_end()

  if triangle_vertices.size() > 0:
    mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in triangle_vertices.size():
      mesh.surface_set_color(triangle_colors[i])
      mesh.surface_add_vertex(triangle_vertices[i])
    mesh.surface_end()


func _emit_command(command: Dictionary) -> void:
  match String(command["type"]):
    "line":
      _emit_styled_segment(
        command["from"],
        command["to"],
        command["color"],
        int(command["style"]),
        bool(command["overhead"]),
      )
    "polyline":
      _emit_polyline(
        command["points"],
        command["color"],
        int(command["style"]),
        bool(command["overhead"]),
      )
    "curve":
      _emit_polyline(
        _sample_curve(command["points"], int(command["curve_type"])),
        command["color"],
        int(command["style"]),
        bool(command["overhead"]),
      )
    "arrow":
      _emit_arrow(
        command["from"],
        command["to"],
        command["color"],
        int(command["point_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "arrow_curve":
      var sampled := _sample_curve(command["points"], int(command["curve_type"]))
      _emit_polyline(sampled, command["color"], int(command["style"]), bool(command["overhead"]))
      if sampled.size() >= 2:
        _emit_arrow_head(
          sampled[sampled.size() - 2],
          sampled[sampled.size() - 1],
          command["color"],
          int(command["point_type"]),
          bool(command["overhead"]),
        )
    "flat_circle":
      _emit_flat_circle(
        command["center"],
        float(command["radius"]),
        command["normal"],
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "flat_rect":
      _emit_flat_rect(
        command["center"],
        command["size"],
        command["axis_u"],
        command["axis_v"],
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "flat_triangle":
      _emit_flat_triangle(
        command["a"],
        command["b"],
        command["c"],
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "cylinder_line":
      _emit_cylinder_between(
        command["from"],
        command["to"],
        float(command["radius"]),
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "cylinder_polyline":
      _emit_cylinder_polyline(
        command["points"],
        float(command["radius"]),
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "cylinder_curve":
      _emit_cylinder_polyline(
        _sample_curve(command["points"], int(command["curve_type"])),
        float(command["radius"]),
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "arrow_3d":
      _emit_arrow_3d(
        command["from"],
        command["to"],
        float(command["radius"]),
        command["color"],
        int(command["point_type"]),
        bool(command["overhead"]),
      )
    "box":
      _emit_box(
        command["center"],
        command["size"],
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "sphere":
      _emit_sphere(
        command["center"],
        float(command["radius"]),
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "cylinder":
      _emit_cylinder(
        command["center"],
        float(command["radius"]),
        float(command["height"]),
        command["axis"],
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "capsule":
      _emit_capsule(
        command["center"],
        float(command["radius"]),
        float(command["height"]),
        command["axis"],
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "cone":
      _emit_cone(
        command["center"],
        float(command["radius"]),
        float(command["height"]),
        command["axis"],
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )


func _emit_polyline(points: PackedVector3Array, color: Color, style: int, overhead: bool) -> void:
  for i in range(points.size() - 1):
    _emit_styled_segment(points[i], points[i + 1], color, style, overhead)


func _emit_styled_segment(
    a: Vector3,
    b: Vector3,
    color: Color,
    style: int,
    overhead: bool,
) -> void:
  var length := a.distance_to(b)
  if length <= 0.0001:
    return

  if style == LineStyle.DASH or style == LineStyle.DOT:
    var segment_length := DOT_LENGTH if style == LineStyle.DOT else DASH_LENGTH
    var gap_length := DOT_GAP if style == LineStyle.DOT else DASH_GAP
    var direction := (b - a) / length
    var distance := 0.0
    while distance < length:
      var start := a + direction * distance
      var end := a + direction * minf(distance + segment_length, length)
      _emit_raw_line(start, end, color, overhead)
      distance += segment_length + gap_length
    return

  _emit_raw_line(a, b, color, overhead)


func _emit_raw_line(a: Vector3, b: Vector3, color: Color, overhead: bool) -> void:
  var vertices := _overhead_line_vertices if overhead else _depth_line_vertices
  var colors := _overhead_line_colors if overhead else _depth_line_colors
  vertices.append(a)
  colors.append(color)
  vertices.append(b)
  colors.append(color)


func _emit_triangle(
    a: Vector3,
    b: Vector3,
    c: Vector3,
    color: Color,
    overhead: bool,
) -> void:
  var vertices := _overhead_triangle_vertices if overhead else _depth_triangle_vertices
  var colors := _overhead_triangle_colors if overhead else _depth_triangle_colors
  vertices.append(a)
  colors.append(color)
  vertices.append(b)
  colors.append(color)
  vertices.append(c)
  colors.append(color)


func _emit_arrow(
    from: Vector3,
    to: Vector3,
    color: Color,
    point_type: int,
    style: int,
    overhead: bool,
) -> void:
  _emit_styled_segment(from, to, color, style, overhead)
  _emit_arrow_head(from, to, color, point_type, overhead)


func _emit_arrow_head(
    from: Vector3,
    to: Vector3,
    color: Color,
    point_type: int,
    overhead: bool,
) -> void:
  if point_type == ArrowPointType.NONE:
    return
  var direction := to - from
  var length := direction.length()
  if length <= 0.0001:
    return

  var n := direction / length
  var axes := _axes_for_normal(n)
  var u: Vector3 = axes[0]
  var v: Vector3 = axes[1]
  var head_length := minf(length * 0.25, 0.8)
  var head_radius := head_length * 0.45
  var base := to - n * head_length

  match point_type:
    ArrowPointType.CIRCLE:
      _emit_circle_outline(to, head_radius, u, v, color, LineStyle.DEFAULT, overhead)
    ArrowPointType.PRISMATIC:
      _emit_raw_line(to, base + u * head_radius, color, overhead)
      _emit_raw_line(to, base - u * head_radius, color, overhead)
      _emit_raw_line(to, base + v * head_radius, color, overhead)
      _emit_raw_line(to, base - v * head_radius, color, overhead)
    _:
      _emit_raw_line(to, base + u * head_radius, color, overhead)
      _emit_raw_line(to, base - u * head_radius, color, overhead)


func _emit_arrow_3d(
    from: Vector3,
    to: Vector3,
    radius: float,
    color: Color,
    point_type: int,
    overhead: bool,
) -> void:
  var length := from.distance_to(to)
  if length <= 0.0001:
    return
  var direction := (to - from) / length
  var head_length := minf(length * 0.28, maxf(radius * 4.0, 0.4))
  var shaft_end := to - direction * head_length
  _emit_cylinder_between(
    from,
    shaft_end,
    radius,
    color,
    MeshType.SOLID,
    LineStyle.DEFAULT,
    overhead,
  )
  if point_type == ArrowPointType.CIRCLE:
    _emit_arrow_head(shaft_end, to, color, point_type, overhead)
  else:
    _emit_cone(
      (shaft_end + to) * 0.5,
      radius * 2.8,
      head_length,
      direction,
      color,
      MeshType.SOLID,
      LineStyle.DEFAULT,
      overhead,
    )


func _emit_flat_circle(
    center: Vector3,
    radius: float,
    normal: Vector3,
    color: Color,
    mesh_type: int,
    style: int,
    overhead: bool,
) -> void:
  var axes := _axes_for_normal(normal)
  var u: Vector3 = axes[0]
  var v: Vector3 = axes[1]
  if mesh_type == MeshType.SOLID or mesh_type == MeshType.MIXED:
    for i in SEGMENTS_CIRCLE:
      var a := TAU * float(i) / float(SEGMENTS_CIRCLE)
      var b := TAU * float(i + 1) / float(SEGMENTS_CIRCLE)
      _emit_triangle(
        center,
        center + (u * cos(a) + v * sin(a)) * radius,
        center + (u * cos(b) + v * sin(b)) * radius,
        color,
        overhead,
      )
  if mesh_type == MeshType.WIREFRAME or mesh_type == MeshType.MIXED:
    _emit_circle_outline(center, radius, u, v, color, style, overhead)


func _emit_flat_rect(
    center: Vector3,
    size: Vector2,
    axis_u: Vector3,
    axis_v: Vector3,
    color: Color,
    mesh_type: int,
    style: int,
    overhead: bool,
) -> void:
  var u := axis_u.normalized() * size.x * 0.5
  var v := axis_v.normalized() * size.y * 0.5
  var corners := PackedVector3Array([center - u - v, center + u - v, center + u + v, center - u + v])
  if mesh_type == MeshType.SOLID or mesh_type == MeshType.MIXED:
    _emit_triangle(corners[0], corners[1], corners[2], color, overhead)
    _emit_triangle(corners[0], corners[2], corners[3], color, overhead)
  if mesh_type == MeshType.WIREFRAME or mesh_type == MeshType.MIXED:
    _emit_closed_outline(corners, color, style, overhead)


func _emit_flat_triangle(
    a: Vector3,
    b: Vector3,
    c: Vector3,
    color: Color,
    mesh_type: int,
    style: int,
    overhead: bool,
) -> void:
  if mesh_type == MeshType.SOLID or mesh_type == MeshType.MIXED:
    _emit_triangle(a, b, c, color, overhead)
  if mesh_type == MeshType.WIREFRAME or mesh_type == MeshType.MIXED:
    _emit_closed_outline(PackedVector3Array([a, b, c]), color, style, overhead)


func _emit_box(
    center: Vector3,
    size: Vector3,
    color: Color,
    mesh_type: int,
    style: int,
    overhead: bool,
) -> void:
  var h := size * 0.5
  var c := PackedVector3Array(
    [
      center + Vector3(-h.x, -h.y, -h.z),
      center + Vector3(h.x, -h.y, -h.z),
      center + Vector3(h.x, -h.y, h.z),
      center + Vector3(-h.x, -h.y, h.z),
      center + Vector3(-h.x, h.y, -h.z),
      center + Vector3(h.x, h.y, -h.z),
      center + Vector3(h.x, h.y, h.z),
      center + Vector3(-h.x, h.y, h.z),
    ],
  )
  if mesh_type == MeshType.SOLID or mesh_type == MeshType.MIXED:
    var faces := PackedInt32Array(
      [
        0,
        1,
        2,
        0,
        2,
        3,
        4,
        6,
        5,
        4,
        7,
        6,
        0,
        4,
        5,
        0,
        5,
        1,
        1,
        5,
        6,
        1,
        6,
        2,
        2,
        6,
        7,
        2,
        7,
        3,
        3,
        7,
        4,
        3,
        4,
        0,
      ],
    )
    for i in range(0, faces.size(), 3):
      _emit_triangle(c[faces[i]], c[faces[i + 1]], c[faces[i + 2]], color, overhead)
  if mesh_type == MeshType.WIREFRAME or mesh_type == MeshType.MIXED:
    var edges := PackedInt32Array(
      [
        0,
        1,
        1,
        2,
        2,
        3,
        3,
        0,
        4,
        5,
        5,
        6,
        6,
        7,
        7,
        4,
        0,
        4,
        1,
        5,
        2,
        6,
        3,
        7,
      ],
    )
    for i in range(0, edges.size(), 2):
      _emit_styled_segment(c[edges[i]], c[edges[i + 1]], color, style, overhead)


func _emit_sphere(
    center: Vector3,
    radius: float,
    color: Color,
    mesh_type: int,
    style: int,
    overhead: bool,
) -> void:
  if mesh_type == MeshType.SOLID or mesh_type == MeshType.MIXED:
    _emit_sphere_solid(center, radius, color, overhead)
  if mesh_type == MeshType.WIREFRAME or mesh_type == MeshType.MIXED:
    _emit_circle_outline(center, radius, Vector3.RIGHT, Vector3.FORWARD, color, style, overhead)
    _emit_circle_outline(center, radius, Vector3.RIGHT, Vector3.UP, color, style, overhead)
    _emit_circle_outline(center, radius, Vector3.UP, Vector3.FORWARD, color, style, overhead)


func _emit_cylinder_between(
    from: Vector3,
    to: Vector3,
    radius: float,
    color: Color,
    mesh_type: int,
    style: int,
    overhead: bool,
) -> void:
  var axis := to - from
  var height := axis.length()
  if height <= 0.0001:
    return
  _emit_cylinder(
    (from + to) * 0.5,
    radius,
    height,
    axis / height,
    color,
    mesh_type,
    style,
    overhead,
  )


func _emit_cylinder_polyline(
    points: PackedVector3Array,
    radius: float,
    color: Color,
    mesh_type: int,
    style: int,
    overhead: bool,
) -> void:
  for i in range(points.size() - 1):
    _emit_cylinder_between(points[i], points[i + 1], radius, color, mesh_type, style, overhead)


func _emit_cylinder(
    center: Vector3,
    radius: float,
    height: float,
    axis: Vector3,
    color: Color,
    mesh_type: int,
    style: int,
    overhead: bool,
) -> void:
  var n := axis.normalized()
  if n.is_zero_approx():
    n = Vector3.UP
  var axes := _axes_for_normal(n)
  var u: Vector3 = axes[0]
  var v: Vector3 = axes[1]
  var top := center + n * height * 0.5
  var bottom := center - n * height * 0.5
  if mesh_type == MeshType.SOLID or mesh_type == MeshType.MIXED:
    for i in SEGMENTS_CIRCLE:
      var a := TAU * float(i) / float(SEGMENTS_CIRCLE)
      var b := TAU * float(i + 1) / float(SEGMENTS_CIRCLE)
      var pa := (u * cos(a) + v * sin(a)) * radius
      var pb := (u * cos(b) + v * sin(b)) * radius
      _emit_triangle(bottom + pa, top + pa, top + pb, color, overhead)
      _emit_triangle(bottom + pa, top + pb, bottom + pb, color, overhead)
      _emit_triangle(top, top + pb, top + pa, color, overhead)
      _emit_triangle(bottom, bottom + pa, bottom + pb, color, overhead)
  if mesh_type == MeshType.WIREFRAME or mesh_type == MeshType.MIXED:
    _emit_circle_outline(top, radius, u, v, color, style, overhead)
    _emit_circle_outline(bottom, radius, u, v, color, style, overhead)
    for i in 4:
      var angle := TAU * float(i) / 4.0
      var offset := (u * cos(angle) + v * sin(angle)) * radius
      _emit_styled_segment(bottom + offset, top + offset, color, style, overhead)


func _emit_capsule(
    center: Vector3,
    radius: float,
    height: float,
    axis: Vector3,
    color: Color,
    mesh_type: int,
    style: int,
    overhead: bool,
) -> void:
  var n := axis.normalized()
  if n.is_zero_approx():
    n = Vector3.UP
  var body_height := maxf(height - radius * 2.0, 0.0)
  if body_height <= 0.0001:
    _emit_sphere(center, radius, color, mesh_type, style, overhead)
    return

  var top := center + n * body_height * 0.5
  var bottom := center - n * body_height * 0.5
  _emit_cylinder(center, radius, body_height, n, color, mesh_type, style, overhead)
  _emit_sphere(top, radius, color, mesh_type, style, overhead)
  _emit_sphere(bottom, radius, color, mesh_type, style, overhead)


func _emit_cone(
    center: Vector3,
    radius: float,
    height: float,
    axis: Vector3,
    color: Color,
    mesh_type: int,
    style: int,
    overhead: bool,
) -> void:
  var n := axis.normalized()
  if n.is_zero_approx():
    n = Vector3.UP
  var axes := _axes_for_normal(n)
  var u: Vector3 = axes[0]
  var v: Vector3 = axes[1]
  var apex := center + n * height * 0.5
  var base := center - n * height * 0.5
  if mesh_type == MeshType.SOLID or mesh_type == MeshType.MIXED:
    for i in SEGMENTS_CIRCLE:
      var a := TAU * float(i) / float(SEGMENTS_CIRCLE)
      var b := TAU * float(i + 1) / float(SEGMENTS_CIRCLE)
      var pa := base + (u * cos(a) + v * sin(a)) * radius
      var pb := base + (u * cos(b) + v * sin(b)) * radius
      _emit_triangle(apex, pa, pb, color, overhead)
      _emit_triangle(base, pb, pa, color, overhead)
  if mesh_type == MeshType.WIREFRAME or mesh_type == MeshType.MIXED:
    _emit_circle_outline(base, radius, u, v, color, style, overhead)
    for i in 4:
      var angle := TAU * float(i) / 4.0
      _emit_styled_segment(
        base + (u * cos(angle) + v * sin(angle)) * radius,
        apex,
        color,
        style,
        overhead,
      )


func _emit_sphere_solid(
    center: Vector3,
    radius: float,
    color: Color,
    overhead: bool,
) -> void:
  var rings := 8
  var segments := 16
  for ring in rings:
    var phi_a := PI * float(ring) / float(rings)
    var phi_b := PI * float(ring + 1) / float(rings)
    for segment in segments:
      var theta_a := TAU * float(segment) / float(segments)
      var theta_b := TAU * float(segment + 1) / float(segments)
      var a := center + _sphere_offset(phi_a, theta_a, radius)
      var b := center + _sphere_offset(phi_b, theta_a, radius)
      var c := center + _sphere_offset(phi_b, theta_b, radius)
      var d := center + _sphere_offset(phi_a, theta_b, radius)
      _emit_triangle(a, b, c, color, overhead)
      _emit_triangle(a, c, d, color, overhead)


func _sphere_offset(phi: float, theta: float, radius: float) -> Vector3:
  return Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta)) * radius


func _emit_circle_outline(
    center: Vector3,
    radius: float,
    axis_u: Vector3,
    axis_v: Vector3,
    color: Color,
    style: int,
    overhead: bool,
) -> void:
  for i in SEGMENTS_CIRCLE:
    var a := TAU * float(i) / float(SEGMENTS_CIRCLE)
    var b := TAU * float(i + 1) / float(SEGMENTS_CIRCLE)
    _emit_styled_segment(
      center + (axis_u * cos(a) + axis_v * sin(a)) * radius,
      center + (axis_u * cos(b) + axis_v * sin(b)) * radius,
      color,
      style,
      overhead,
    )


func _emit_closed_outline(
    points: PackedVector3Array,
    color: Color,
    style: int,
    overhead: bool,
) -> void:
  for i in points.size():
    _emit_styled_segment(points[i], points[(i + 1) % points.size()], color, style, overhead)


func _sample_curve(points: PackedVector3Array, curve_type: int) -> PackedVector3Array:
  if points.size() < 2:
    return points
  if curve_type == CurveType.LINES or points.size() < 3:
    return points
  if curve_type == CurveType.CLOSED_ROUND_CORNER:
    # 第一版只保留闭合语义，圆角采样后续再按视觉需求细化。
    var closed := points.duplicate()
    closed.append(points[0])
    return closed
  if curve_type == CurveType.BEZIER and points.size() >= 4:
    return _sample_bezier(points[0], points[1], points[2], points[3])
  if curve_type == CurveType.HERMITE and points.size() >= 4:
    return _sample_hermite(points[0], points[1], points[2], points[3])
  return _sample_catmull_rom(points)


func _sample_bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> PackedVector3Array:
  var result := PackedVector3Array()
  for i in range(SEGMENTS_CURVE + 1):
    var t := float(i) / float(SEGMENTS_CURVE)
    var omt := 1.0 - t
    result.append(
      omt * omt * omt * p0 + 3.0 * omt * omt * t * p1
      + 3.0 * omt * t * t * p2 + t * t * t * p3,
    )
  return result


func _sample_hermite(p0: Vector3, p1: Vector3, t0: Vector3, t1: Vector3) -> PackedVector3Array:
  var result := PackedVector3Array()
  for i in range(SEGMENTS_CURVE + 1):
    var t := float(i) / float(SEGMENTS_CURVE)
    var t2 := t * t
    var t3 := t2 * t
    result.append(
      (2.0 * t3 - 3.0 * t2 + 1.0) * p0
      + (t3 - 2.0 * t2 + t) * t0 + (-2.0 * t3 + 3.0 * t2) * p1
      + (t3 - t2) * t1,
    )
  return result


func _sample_catmull_rom(points: PackedVector3Array) -> PackedVector3Array:
  var result := PackedVector3Array()
  for i in range(points.size() - 1):
    var p0 := points[maxi(i - 1, 0)]
    var p1 := points[i]
    var p2 := points[i + 1]
    var p3 := points[mini(i + 2, points.size() - 1)]
    for step in SEGMENTS_CURVE:
      var t := float(step) / float(SEGMENTS_CURVE)
      var t2 := t * t
      var t3 := t2 * t
      result.append(
        0.5 * ((2.0 * p1) + (-p0 + p2) * t
            + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
            + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3),
      )
  result.append(points[points.size() - 1])
  return result


func _axes_for_normal(normal: Vector3) -> Array[Vector3]:
  var n := normal.normalized()
  if n.is_zero_approx():
    n = Vector3.UP
  var u := n.cross(Vector3.UP)
  if u.length_squared() <= 0.0001:
    u = n.cross(Vector3.RIGHT)
  u = u.normalized()
  var v := n.cross(u).normalized()
  return [u, v]
