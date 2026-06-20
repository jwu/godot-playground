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
const SEGMENTS_CIRCLE := 40
const RING_SEGMENT_COUNT := 24
const ROUND_CORNER_SEGMENT_COUNT := 10
const ROUND_CORNER_RADIUS_SCALE := 2.0
const CURVE_3D_SEGMENT_LENGTH := 0.4
const CURVE_JOINT_SPHERE_RINGS := 4
const CURVE_JOINT_SPHERE_SEGMENTS := 8
const DASH_LENGTH := 0.45
const DASH_GAP := 0.25
const DOT_LENGTH := 0.08
const DOT_GAP := 0.22
const MIXED_SOLID_ALPHA := 0.2

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


func draw_cylinder_arrow_curve(
    points: PackedVector3Array,
    radius: float,
    color: Color = Color.WHITE,
    curve_type: CurveType = CurveType.CATMULL_ROM,
    point_type: ArrowPointType = ArrowPointType.PRISMATIC,
    mesh_type: MeshType = MeshType.SOLID,
    style: LineStyle = LineStyle.DEFAULT,
    overhead: bool = false,
    layer: int = DEFAULT_LAYER,
) -> void:
  _commands.append(
    {
      "type": "cylinder_arrow_curve",
      "points": points,
      "radius": radius,
      "color": color,
      "curve_type": curve_type,
      "point_type": point_type,
      "mesh_type": mesh_type,
      "style": style,
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
      if sampled.size() >= 2:
        var head_length := _arrow_head_length(sampled[0].distance_to(sampled[sampled.size() - 1]))
        var trimmed := _trim_polyline_end(sampled, head_length)
        _emit_polyline(sampled, command["color"], int(command["style"]), bool(command["overhead"]))
        _emit_arrow_head(
          trimmed[trimmed.size() - 1],
          sampled[sampled.size() - 1],
          command["color"],
          int(command["point_type"]),
          bool(command["overhead"]),
          head_length,
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
        _sample_curve(command["points"], int(command["curve_type"]), float(command["radius"])),
        float(command["radius"]),
        command["color"],
        int(command["mesh_type"]),
        int(command["style"]),
        bool(command["overhead"]),
      )
    "cylinder_arrow_curve":
      var sampled_curve := _sample_curve(
        command["points"],
        int(command["curve_type"]),
        float(command["radius"]),
      )
      if sampled_curve.size() >= 2:
        var cone_radius := float(command["radius"]) * 4.0
        var cone_height := cone_radius * 2.0
        var trimmed_curve := _trim_polyline_end(sampled_curve, cone_height)
        _emit_cylinder_polyline(
          trimmed_curve,
          float(command["radius"]),
          command["color"],
          int(command["mesh_type"]),
          int(command["style"]),
          bool(command["overhead"]),
        )
        _emit_arrow_3d_head(
          trimmed_curve[trimmed_curve.size() - 1],
          sampled_curve[sampled_curve.size() - 1],
          cone_radius,
          cone_height,
          command["color"],
          int(command["point_type"]),
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


func _mixed_solid_color(color: Color) -> Color:
  return Color(color.r, color.g, color.b, MIXED_SOLID_ALPHA)


func _solid_color(color: Color, mesh_type: int) -> Color:
  if mesh_type == MeshType.MIXED:
    return _mixed_solid_color(color)
  return color


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
    head_length_override: float = -1.0,
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
  var head_length := _arrow_head_length(length)
  if head_length_override > 0.0:
    head_length = head_length_override
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
  if point_type == ArrowPointType.NONE:
    _emit_cylinder_between(from, to, radius, color, MeshType.SOLID, LineStyle.DEFAULT, overhead)
    return

  var cone_radius := radius * 2.0
  var cone_height := minf(cone_radius * 1.5, length * 0.8)
  var direction := (to - from) / length
  var shaft_end := to - direction * cone_height
  _emit_cylinder_between(
    from,
    shaft_end,
    radius,
    color,
    MeshType.SOLID,
    LineStyle.DEFAULT,
    overhead,
  )
  _emit_arrow_3d_head(shaft_end, to, cone_radius, cone_height, color, point_type, overhead)


func _emit_arrow_3d_head(
    from: Vector3,
    to: Vector3,
    cone_radius: float,
    cone_height: float,
    color: Color,
    point_type: int,
    overhead: bool,
) -> void:
  if point_type == ArrowPointType.NONE:
    return
  if point_type == ArrowPointType.CIRCLE:
    _emit_arrow_head(from, to, color, point_type, overhead)
    return

  var direction := to - from
  if direction.length_squared() <= 0.0001:
    return
  _emit_cone(
    (from + to) * 0.5,
    cone_radius,
    cone_height,
    direction.normalized(),
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
    var solid_color := _solid_color(color, mesh_type)
    for i in SEGMENTS_CIRCLE:
      var a := TAU * float(i) / float(SEGMENTS_CIRCLE)
      var b := TAU * float(i + 1) / float(SEGMENTS_CIRCLE)
      _emit_triangle(
        center,
        center + (u * cos(a) + v * sin(a)) * radius,
        center + (u * cos(b) + v * sin(b)) * radius,
        solid_color,
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
    var solid_color := _solid_color(color, mesh_type)
    _emit_triangle(corners[0], corners[1], corners[2], solid_color, overhead)
    _emit_triangle(corners[0], corners[2], corners[3], solid_color, overhead)
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
    _emit_triangle(a, b, c, _solid_color(color, mesh_type), overhead)
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
    var solid_color := _solid_color(color, mesh_type)
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
      _emit_triangle(c[faces[i]], c[faces[i + 1]], c[faces[i + 2]], solid_color, overhead)
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
    _emit_sphere_solid(center, radius, _solid_color(color, mesh_type), overhead)
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
  if points.size() < 2:
    return
  if radius <= 0.0:
    _emit_polyline(points, color, style, overhead)
    return

  if mesh_type == MeshType.SOLID or mesh_type == MeshType.MIXED:
    var solid_color := _solid_color(color, mesh_type)
    for point: Vector3 in points:
      _emit_curve_joint_sphere(point, radius, solid_color, overhead)
    _emit_tube_polyline(points, radius, solid_color, overhead)

  if mesh_type == MeshType.WIREFRAME or mesh_type == MeshType.MIXED:
    for i in range(points.size() - 1):
      _emit_cylinder_between(
        points[i],
        points[i + 1],
        radius,
        color,
        MeshType.WIREFRAME,
        style,
        overhead,
      )


func _emit_curve_joint_sphere(
    center: Vector3,
    radius: float,
    color: Color,
    overhead: bool,
) -> void:
  for ring in CURVE_JOINT_SPHERE_RINGS:
    var phi_a := PI * float(ring) / float(CURVE_JOINT_SPHERE_RINGS)
    var phi_b := PI * float(ring + 1) / float(CURVE_JOINT_SPHERE_RINGS)
    for segment in CURVE_JOINT_SPHERE_SEGMENTS:
      var theta_a := TAU * float(segment) / float(CURVE_JOINT_SPHERE_SEGMENTS)
      var theta_b := TAU * float(segment + 1) / float(CURVE_JOINT_SPHERE_SEGMENTS)
      var a := center + _sphere_offset(phi_a, theta_a, radius)
      var b := center + _sphere_offset(phi_b, theta_a, radius)
      var c := center + _sphere_offset(phi_b, theta_b, radius)
      var d := center + _sphere_offset(phi_a, theta_b, radius)
      _emit_triangle(a, b, c, color, overhead)
      _emit_triangle(a, c, d, color, overhead)


func _sphere_offset(phi: float, theta: float, radius: float) -> Vector3:
  return Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta)) * radius


func _emit_tube_polyline(
    points: PackedVector3Array,
    radius: float,
    color: Color,
    overhead: bool,
) -> void:
  var previous_ring := PackedVector3Array()
  var previous_normal := Vector3.UP
  for i in points.size():
    var direction := _polyline_direction_at(points, i)
    if direction.is_zero_approx():
      continue
    var normal := _transport_ring_normal(direction, previous_normal)
    var ring := _make_ring(points[i], direction, normal, radius, RING_SEGMENT_COUNT)
    if previous_ring.size() == ring.size():
      _emit_ring_bridge(previous_ring, ring, color, overhead)
    previous_ring = ring
    previous_normal = normal


func _polyline_direction_at(points: PackedVector3Array, index: int) -> Vector3:
  if points.size() < 2:
    return Vector3.ZERO
  if index <= 0:
    return (points[1] - points[0]).normalized()
  if index >= points.size() - 1:
    return (points[index] - points[index - 1]).normalized()
  var previous := (points[index] - points[index - 1]).normalized()
  var next := (points[index + 1] - points[index]).normalized()
  var averaged := previous + next
  if averaged.length_squared() <= 0.0001:
    return next
  return averaged.normalized()


func _transport_ring_normal(direction: Vector3, previous_normal: Vector3) -> Vector3:
  var tangent := direction.normalized()
  var helper := previous_normal
  if helper.cross(tangent).length_squared() <= 0.0001:
    helper = Vector3.RIGHT if absf(tangent.dot(Vector3.RIGHT)) < 0.95 else Vector3.UP
  var bitangent := helper.cross(tangent).normalized()
  return tangent.cross(bitangent).normalized()


func _make_ring(
    center: Vector3,
    direction: Vector3,
    normal: Vector3,
    radius: float,
    segment_count: int,
) -> PackedVector3Array:
  var ring := PackedVector3Array()
  var axis := direction.normalized()
  for i in segment_count:
    var angle := TAU * float(i) / float(segment_count)
    ring.append(center + normal.rotated(axis, angle) * radius)
  return ring


func _emit_ring_bridge(
    previous_ring: PackedVector3Array,
    current_ring: PackedVector3Array,
    color: Color,
    overhead: bool,
) -> void:
  var segment_count := mini(previous_ring.size(), current_ring.size())
  for i in segment_count:
    var next := (i + 1) % segment_count
    _emit_triangle(previous_ring[i], previous_ring[next], current_ring[i], color, overhead)
    _emit_triangle(previous_ring[next], current_ring[next], current_ring[i], color, overhead)


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
    var solid_color := _solid_color(color, mesh_type)
    for i in SEGMENTS_CIRCLE:
      var a := TAU * float(i) / float(SEGMENTS_CIRCLE)
      var b := TAU * float(i + 1) / float(SEGMENTS_CIRCLE)
      var pa := (u * cos(a) + v * sin(a)) * radius
      var pb := (u * cos(b) + v * sin(b)) * radius
      _emit_triangle(bottom + pa, top + pa, top + pb, solid_color, overhead)
      _emit_triangle(bottom + pa, top + pb, bottom + pb, solid_color, overhead)
      _emit_triangle(top, top + pb, top + pa, solid_color, overhead)
      _emit_triangle(bottom, bottom + pa, bottom + pb, solid_color, overhead)
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
  if radius <= 0.0 or height <= 0.0:
    return
  var n := axis.normalized()
  if n.is_zero_approx():
    n = Vector3.UP

  if mesh_type == MeshType.SOLID or mesh_type == MeshType.MIXED:
    _emit_capsule_solid(center, radius, height, n, _solid_color(color, mesh_type), overhead)
  if mesh_type == MeshType.WIREFRAME or mesh_type == MeshType.MIXED:
    _emit_capsule_wireframe(center, radius, height, n, color, style, overhead)


func _emit_capsule_solid(
    center: Vector3,
    radius: float,
    height: float,
    axis: Vector3,
    color: Color,
    overhead: bool,
) -> void:
  var axes := _axes_for_normal(axis)
  var u: Vector3 = axes[0]
  var v: Vector3 = axes[1]
  var points := SEGMENTS_CIRCLE + 1
  var top_count := ceili(float(points) * 0.5)
  var bottom_start := floori(float(points) * 0.5)
  var y_offset := maxf((height - radius * 2.0) * 0.5, 0.0)
  var rings: Array[PackedVector3Array] = []

  for y in top_count:
    rings.append(_capsule_ring(center, axis, u, v, radius, y_offset, y, points, true))
  for y in range(bottom_start, points):
    rings.append(_capsule_ring(center, axis, u, v, radius, y_offset, y, points, false))
  for i in range(rings.size() - 1):
    _emit_ring_bridge(rings[i], rings[i + 1], color, overhead)


func _capsule_ring(
    center: Vector3,
    axis: Vector3,
    axis_u: Vector3,
    axis_v: Vector3,
    radius: float,
    y_offset: float,
    index: int,
    points: int,
    is_top: bool,
) -> PackedVector3Array:
  var angle := PI * float(index) / float(points - 1)
  var ring_radius := sin(angle) * radius
  var axis_offset := cos(angle) * radius
  if is_top:
    axis_offset += y_offset
  else:
    axis_offset -= y_offset

  var ring := PackedVector3Array()
  for i in SEGMENTS_CIRCLE:
    var theta := TAU * float(i) / float(SEGMENTS_CIRCLE)
    ring.append(
      center + axis * axis_offset
      + (axis_u * cos(theta) + axis_v * sin(theta)) * ring_radius,
    )
  return ring


func _emit_capsule_wireframe(
    center: Vector3,
    radius: float,
    height: float,
    axis: Vector3,
    color: Color,
    style: int,
    overhead: bool,
) -> void:
  var axes := _axes_for_normal(axis)
  var u: Vector3 = axes[0]
  var v: Vector3 = axes[1]
  var y_offset := maxf((height - radius * 2.0) * 0.5, 0.0)
  _emit_capsule_outline(center, radius, y_offset, axis, u, color, style, overhead)
  _emit_capsule_outline(center, radius, y_offset, axis, v, color, style, overhead)
  _emit_circle_outline(center + axis * y_offset, radius, u, v, color, style, overhead)
  _emit_circle_outline(center - axis * y_offset, radius, u, v, color, style, overhead)


func _emit_capsule_outline(
    center: Vector3,
    radius: float,
    y_offset: float,
    axis: Vector3,
    side_axis: Vector3,
    color: Color,
    style: int,
    overhead: bool,
) -> void:
  var points := PackedVector3Array()
  var half_segments := int(float(SEGMENTS_CIRCLE) / 2.0)
  for i in range(half_segments + 1):
    var angle := PI * float(i) / float(half_segments)
    points.append(center + axis * y_offset + axis * sin(angle) * radius + side_axis * cos(angle) * radius)
  for i in range(half_segments + 1):
    var angle := PI + PI * float(i) / float(half_segments)
    points.append(center - axis * y_offset + axis * sin(angle) * radius + side_axis * cos(angle) * radius)
  _emit_closed_outline(points, color, style, overhead)


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
    var solid_color := _solid_color(color, mesh_type)
    for i in SEGMENTS_CIRCLE:
      var a := TAU * float(i) / float(SEGMENTS_CIRCLE)
      var b := TAU * float(i + 1) / float(SEGMENTS_CIRCLE)
      var pa := base + (u * cos(a) + v * sin(a)) * radius
      var pb := base + (u * cos(b) + v * sin(b)) * radius
      _emit_triangle(apex, pa, pb, solid_color, overhead)
      _emit_triangle(base, pb, pa, solid_color, overhead)
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
  var side_vertex_count := 15
  var side_segment_count := side_vertex_count - 1
  for face in 6:
    for y in side_segment_count:
      for x in side_segment_count:
        var a := center + _cube_sphere_point(face, x, y, side_segment_count, radius)
        var b := center + _cube_sphere_point(face, x + 1, y, side_segment_count, radius)
        var c := center + _cube_sphere_point(face, x + 1, y + 1, side_segment_count, radius)
        var d := center + _cube_sphere_point(face, x, y + 1, side_segment_count, radius)
        _emit_triangle(a, b, c, color, overhead)
        _emit_triangle(a, c, d, color, overhead)


func _cube_sphere_point(
    face: int,
    x_index: int,
    y_index: int,
    side_segment_count: int,
    radius: float,
) -> Vector3:
  var x := -1.0 + 2.0 * float(x_index) / float(side_segment_count)
  var y := -1.0 + 2.0 * float(y_index) / float(side_segment_count)
  var cube_point := Vector3.ZERO
  match face:
    0:
      cube_point = Vector3(x, y, -1.0)
    1:
      cube_point = Vector3(-x, y, 1.0)
    2:
      cube_point = Vector3(x, -1.0, -y)
    3:
      cube_point = Vector3(x, 1.0, y)
    4:
      cube_point = Vector3(-1.0, y, x)
    _:
      cube_point = Vector3(1.0, y, -x)

  var x2 := cube_point.x * cube_point.x
  var y2 := cube_point.y * cube_point.y
  var z2 := cube_point.z * cube_point.z
  return Vector3(
    cube_point.x * sqrt(1.0 - y2 * 0.5 - z2 * 0.5 + y2 * z2 / 3.0),
    cube_point.y * sqrt(1.0 - x2 * 0.5 - z2 * 0.5 + x2 * z2 / 3.0),
    cube_point.z * sqrt(1.0 - x2 * 0.5 - y2 * 0.5 + x2 * y2 / 3.0),
  ) * radius


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


func _sample_curve(
    points: PackedVector3Array,
    curve_type: int,
    stroke_radius: float = 0.0,
) -> PackedVector3Array:
  if points.size() < 2:
    return points
  if curve_type == CurveType.LINES or points.size() < 3:
    return points
  if curve_type == CurveType.BEZIER and points.size() >= 4:
    return _sample_bezier_curve(points)
  if curve_type == CurveType.HERMITE and points.size() >= 4:
    return _sample_hermite_curve(points)
  if curve_type == CurveType.ROUND_CORNER:
    return _sample_round_corner(points, false, stroke_radius)
  if curve_type == CurveType.CLOSED_ROUND_CORNER:
    return _sample_round_corner(points, true, stroke_radius)
  return _sample_catmull_rom(points)


func _sample_bezier_curve(points: PackedVector3Array) -> PackedVector3Array:
  var result := PackedVector3Array()
  for i in range(0, points.size() - 3, 3):
    var segment_count := _curve_segment_count_bezier(
      points[i],
      points[i + 1],
      points[i + 2],
      points[i + 3],
    )
    for step in range(segment_count + 1):
      if result.size() > 0 and step == 0:
        continue
      result.append(_sample_bezier(points[i], points[i + 1], points[i + 2], points[i + 3], step, segment_count))
  return result


func _sample_bezier(
    p0: Vector3,
    p1: Vector3,
    p2: Vector3,
    p3: Vector3,
    step: int,
    segment_count: int,
) -> Vector3:
  var t := float(step) / float(segment_count)
  var omt := 1.0 - t
  return (
      omt * omt * omt * p0 + 3.0 * omt * omt * t * p1
      + 3.0 * omt * t * t * p2 + t * t * t * p3
  )


func _sample_hermite_curve(points: PackedVector3Array) -> PackedVector3Array:
  var result := PackedVector3Array()
  for i in range(int(float(points.size()) / 2.0) - 1):
    var p0 := points[i * 2]
    var tangent_point0 := points[i * 2 + 1]
    var p1 := points[i * 2 + 2]
    var tangent_point1 := points[i * 2 + 3]
    var tangent0 := tangent_point0 - p0
    var tangent1 := tangent_point1 - p1
    var segment_count := _curve_segment_count_polyline(PackedVector3Array([p0, tangent_point0, p1]))
    for step in range(segment_count + 1):
      if result.size() > 0 and step == 0:
        continue
      result.append(_sample_hermite(p0, p1, tangent0, tangent1, step, segment_count))
  return result


func _sample_hermite(
    p0: Vector3,
    p1: Vector3,
    tangent0: Vector3,
    tangent1: Vector3,
    step: int,
    segment_count: int,
) -> Vector3:
  var t := float(step) / float(segment_count)
  var t2 := t * t
  var t3 := t2 * t
  return (
      (2.0 * t3 - 3.0 * t2 + 1.0) * p0
      + (t3 - 2.0 * t2 + t) * tangent0 + (-2.0 * t3 + 3.0 * t2) * p1
      + (t3 - t2) * tangent1
  )


func _sample_catmull_rom(points: PackedVector3Array) -> PackedVector3Array:
  var result := PackedVector3Array()
  for i in range(points.size() - 1):
    var p0 := points[maxi(i - 1, 0)]
    var p1 := points[i]
    var p2 := points[i + 1]
    var p3 := points[mini(i + 2, points.size() - 1)]
    var segment_count := _curve_segment_count_polyline(PackedVector3Array([p1, p2]))
    for step in segment_count:
      var t := float(step) / float(segment_count)
      var t2 := t * t
      var t3 := t2 * t
      result.append(
        0.5 * ((2.0 * p1) + (-p0 + p2) * t
            + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
            + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3),
      )
  result.append(points[points.size() - 1])
  return result


func _sample_round_corner(
    points: PackedVector3Array,
    closed: bool,
    stroke_radius: float,
) -> PackedVector3Array:
  if points.size() < 3:
    return points
  var result := PackedVector3Array()
  var point_count := points.size()
  if not closed:
    result.append(points[0])

  var start_index := 0 if closed else 1
  var end_index := point_count if closed else point_count - 1
  for i in range(start_index, end_index):
    var previous := points[(i - 1 + point_count) % point_count]
    var current := points[i % point_count]
    var next := points[(i + 1) % point_count]
    _append_round_corner(result, previous, current, next, stroke_radius)

  if closed:
    result.append(result[0])
  else:
    result.append(points[point_count - 1])
  return result


func _append_round_corner(
    result: PackedVector3Array,
    previous: Vector3,
    current: Vector3,
    next: Vector3,
    stroke_radius: float,
) -> void:
  var to_previous := previous - current
  var to_next := next - current
  var previous_length := to_previous.length()
  var next_length := to_next.length()
  if previous_length <= 0.0001 or next_length <= 0.0001:
    result.append(current)
    return

  var previous_dir := to_previous / previous_length
  var next_dir := to_next / next_length
  var cos_degree := clampf(previous_dir.dot(next_dir), -0.999, 0.999)
  var half_degree := acos(cos_degree) * 0.5
  if half_degree <= 0.0001:
    result.append(current)
    return

  var corner_radius := stroke_radius * ROUND_CORNER_RADIUS_SCALE
  if corner_radius <= 0.0:
    corner_radius = minf(previous_length, next_length) * 0.25
  var tangent_length := minf(corner_radius / tan(half_degree), minf(previous_length, next_length) * 0.45)
  var start := current + previous_dir * tangent_length
  var end := current + next_dir * tangent_length
  var center_dir := previous_dir + next_dir
  var rotate_axis := to_previous.cross(to_next).normalized()
  if center_dir.length_squared() <= 0.0001 or rotate_axis.length_squared() <= 0.0001:
    _append_quadratic_corner(result, start, current, end)
    return

  var center := current + center_dir.normalized() * (tangent_length / cos(half_degree))
  var start_offset := start - center
  var end_offset := end - center
  var signed_angle := start_offset.signed_angle_to(end_offset, rotate_axis)
  if absf(signed_angle) <= 0.0001:
    _append_quadratic_corner(result, start, current, end)
    return

  for step in range(ROUND_CORNER_SEGMENT_COUNT + 1):
    if result.size() > 0 and step == 0:
      result.append(start)
      continue
    var t := float(step) / float(ROUND_CORNER_SEGMENT_COUNT)
    result.append(center + start_offset.rotated(rotate_axis, signed_angle * t))


func _append_quadratic_corner(
    result: PackedVector3Array,
    start: Vector3,
    control: Vector3,
    end: Vector3,
) -> void:
  for step in range(ROUND_CORNER_SEGMENT_COUNT + 1):
    if result.size() > 0 and step == 0:
      result.append(start)
      continue
    var t := float(step) / float(ROUND_CORNER_SEGMENT_COUNT)
    var omt := 1.0 - t
    result.append(omt * omt * start + 2.0 * omt * t * control + t * t * end)


func _curve_segment_count_bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> int:
  return maxi(1, floori(_approximate_bezier_length(p0, p1, p2, p3) / CURVE_3D_SEGMENT_LENGTH))


func _curve_segment_count_polyline(points: PackedVector3Array) -> int:
  return maxi(1, floori(_polyline_length(points) / CURVE_3D_SEGMENT_LENGTH))


func _approximate_bezier_length(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> float:
  var length := 0.0
  var previous := p0
  for step in range(1, 9):
    var current := _sample_bezier(p0, p1, p2, p3, step, 8)
    length += previous.distance_to(current)
    previous = current
  return length


func _arrow_head_length(length: float) -> float:
  return minf(length * 0.25, 0.8)


func _polyline_length(points: PackedVector3Array) -> float:
  var length := 0.0
  for i in range(points.size() - 1):
    length += points[i].distance_to(points[i + 1])
  return length


func _trim_polyline_end(points: PackedVector3Array, distance: float) -> PackedVector3Array:
  if points.size() < 2 or distance <= 0.0:
    return points
  var result := points.duplicate()
  var remaining := distance
  while result.size() >= 2 and remaining > 0.0:
    var last := result[result.size() - 1]
    var previous := result[result.size() - 2]
    var segment_length := previous.distance_to(last)
    if segment_length <= 0.0001:
      result.remove_at(result.size() - 1)
      continue
    if segment_length > remaining:
      var direction := (last - previous) / segment_length
      result[result.size() - 1] = last - direction * remaining
      return result
    remaining -= segment_length
    result.remove_at(result.size() - 1)
  return PackedVector3Array([points[0], points[0]])


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
