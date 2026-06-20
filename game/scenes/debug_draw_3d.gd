extends Node3D
## DebugDraw3D：3D 调试绘制演示基础场景，FreeCamera + 共享 DebugDraw3D 节点
##
## 当前场景只保留浏览、网格和共享绘制节点基础设施。
## Esc 在 Freelook 中退出 Freelook，否则返回主菜单。

const DebugDraw3DNode := preload("res://shared/debug_draw_3d/debug_draw_3d.gd")
const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const LABEL_FONT_SIZE := 18
const LABEL_PIXEL_SIZE := 0.008
const DEMO_COLUMN_GAP := 2.0

var _last_info_text := ""
var _demo_labels: Node3D
var _origin_axes_labels: Node3D

@onready var _free_camera: FreeCamera = $FreeCamera
@onready var _info_label: Label = $UI/InfoLabel
@onready var _debug_draw: DebugDraw3DNode = %DebugDraw3D


func _ready() -> void:
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(roundi(DESIGN_WIDTH * dpi_scale), roundi(DESIGN_HEIGHT * dpi_scale))
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
  _setup_origin_axes_labels()
  _setup_draw_line_labels()
  _setup_draw_polyline_labels()
  _setup_draw_curve_labels()
  _setup_draw_arrow_labels()
  _setup_draw_arrow_curve_labels()
  _update_info_label()


func _process(_delta: float) -> void:
  _update_info_label()
  _draw_origin_axes()
  _draw_line_demos()
  _draw_polyline_demos()
  _draw_curve_demos()
  _draw_arrow_demos()
  _draw_arrow_curve_demos()


func _input(event: InputEvent) -> void:
  if event.is_action_pressed(&"ui_cancel"):
    if _free_camera.is_freelook_active():
      _free_camera.set_freelook_active(false)
    else:
      get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _update_info_label() -> void:
  var text := _free_camera.get_info_text()
  if text != _last_info_text:
    _info_label.text = text
    _last_info_text = text


func _draw_origin_axes() -> void:
  var axis_len := 1.0
  _debug_draw.draw_line(Vector3.ZERO, Vector3.RIGHT * axis_len, Color.RED)
  _debug_draw.draw_line(Vector3.ZERO, Vector3.LEFT * axis_len, Color(0.35, 0.0, 0.0, 1.0))
  _debug_draw.draw_line(Vector3.ZERO, Vector3.UP * axis_len, Color.GREEN)
  _debug_draw.draw_line(Vector3.ZERO, Vector3.DOWN * axis_len, Color(0.0, 0.35, 0.0, 1.0))
  _debug_draw.draw_line(Vector3.ZERO, Vector3.BACK * axis_len, Color.BLUE)
  _debug_draw.draw_line(Vector3.ZERO, Vector3.FORWARD * axis_len, Color(0.0, 0.0, 0.35, 1.0))


func _draw_line_demos() -> void:
  var origin := Vector3(1.0, 0.1, -1.0)
  var row_gap := Vector3(0.0, 0.0, -1.0)
  var line_delta := Vector3(2.0, 0.0, 0.0)

  _debug_draw.draw_line(origin, origin + line_delta, Color.WHITE)
  _debug_draw.draw_line(
    origin + row_gap,
    origin + row_gap + line_delta,
    Color.RED,
    DebugDraw3DNode.LineStyle.DASH,
  )
  _debug_draw.draw_line(
    origin + row_gap * 2.0,
    origin + row_gap * 2.0 + line_delta,
    Color.GREEN,
    DebugDraw3DNode.LineStyle.DOT,
  )
  _debug_draw.draw_line(
    origin + row_gap * 3.0,
    origin + row_gap * 3.0 + line_delta,
    Color.YELLOW,
    DebugDraw3DNode.LineStyle.DEFAULT,
    true,
  )


func _draw_polyline_demos() -> void:
  var draw_line_end_x := 3.0
  var origin := Vector3(draw_line_end_x + DEMO_COLUMN_GAP, 0.1, -1.0)
  var row_gap := Vector3(0.0, 0.0, -1.0)

  _debug_draw.draw_polyline(_make_polyline_points(origin), Color.WHITE)
  _debug_draw.draw_polyline(
    _make_polyline_points(origin + row_gap),
    Color.RED,
    DebugDraw3DNode.LineStyle.DASH,
  )
  _debug_draw.draw_polyline(
    _make_polyline_points(origin + row_gap * 2.0),
    Color.GREEN,
    DebugDraw3DNode.LineStyle.DOT,
  )
  _debug_draw.draw_polyline(
    _make_polyline_points(origin + row_gap * 3.0),
    Color.YELLOW,
    DebugDraw3DNode.LineStyle.DEFAULT,
    true,
  )


func _draw_curve_demos() -> void:
  var draw_polyline_end_x := 6.8
  var origin := Vector3(draw_polyline_end_x + DEMO_COLUMN_GAP, 0.1, -1.0)
  var row_gap := Vector3(0.0, 0.0, -1.0)

  _debug_draw.draw_curve(
    _make_curve_points(origin),
    Color.WHITE,
    DebugDraw3DNode.CurveType.BEZIER,
  )
  _debug_draw.draw_curve(
    _make_curve_points(origin + row_gap),
    Color.RED,
    DebugDraw3DNode.CurveType.CATMULL_ROM,
  )
  _debug_draw.draw_curve(
    _make_curve_points(origin + row_gap * 2.0),
    Color.GREEN,
    DebugDraw3DNode.CurveType.ROUND_CORNER,
  )
  _debug_draw.draw_curve(
    _make_curve_points(origin + row_gap * 3.0),
    Color.CYAN,
    DebugDraw3DNode.CurveType.CLOSED_ROUND_CORNER,
  )
  _debug_draw.draw_curve(
    _make_curve_points(origin + row_gap * 4.0),
    Color.YELLOW,
    DebugDraw3DNode.CurveType.LINES,
  )
  _debug_draw.draw_curve(
    _make_curve_points(origin + row_gap * 5.0),
    Color.MAGENTA,
    DebugDraw3DNode.CurveType.HERMITE,
  )


func _draw_arrow_demos() -> void:
  var draw_curve_end_x := 10.6
  var origin := Vector3(draw_curve_end_x + DEMO_COLUMN_GAP, 0.1, -1.0)
  var row_gap := Vector3(0.0, 0.0, -1.0)
  var arrow_delta := Vector3(2.0, 0.0, 0.0)

  _debug_draw.draw_arrow(
    origin,
    origin + arrow_delta,
    Color.WHITE,
    DebugDraw3DNode.ArrowPointType.NONE,
  )
  _debug_draw.draw_arrow(
    origin + row_gap,
    origin + row_gap + arrow_delta,
    Color.RED,
    DebugDraw3DNode.ArrowPointType.TRIANGLE,
  )
  _debug_draw.draw_arrow(
    origin + row_gap * 2.0,
    origin + row_gap * 2.0 + arrow_delta,
    Color.GREEN,
    DebugDraw3DNode.ArrowPointType.PRISMATIC,
  )
  _debug_draw.draw_arrow(
    origin + row_gap * 3.0,
    origin + row_gap * 3.0 + arrow_delta,
    Color.CYAN,
    DebugDraw3DNode.ArrowPointType.CIRCLE,
  )
  _debug_draw.draw_arrow(
    origin + row_gap * 4.0,
    origin + row_gap * 4.0 + arrow_delta,
    Color.YELLOW,
    DebugDraw3DNode.ArrowPointType.TRIANGLE,
    DebugDraw3DNode.LineStyle.DASH,
  )
  _debug_draw.draw_arrow(
    origin + row_gap * 5.0,
    origin + row_gap * 5.0 + arrow_delta,
    Color.MAGENTA,
    DebugDraw3DNode.ArrowPointType.TRIANGLE,
    DebugDraw3DNode.LineStyle.DOT,
  )
  _debug_draw.draw_arrow(
    origin + row_gap * 6.0,
    origin + row_gap * 6.0 + arrow_delta,
    Color.ORANGE,
    DebugDraw3DNode.ArrowPointType.TRIANGLE,
    DebugDraw3DNode.LineStyle.DEFAULT,
    true,
  )


func _draw_arrow_curve_demos() -> void:
  var draw_arrow_end_x := 14.6
  var origin := Vector3(draw_arrow_end_x + DEMO_COLUMN_GAP, 0.1, -1.0)
  var row_gap := Vector3(0.0, 0.0, -1.0)

  _debug_draw.draw_arrow_curve(
    _make_curve_points(origin),
    Color.WHITE,
    DebugDraw3DNode.CurveType.BEZIER,
  )
  _debug_draw.draw_arrow_curve(
    _make_curve_points(origin + row_gap),
    Color.RED,
    DebugDraw3DNode.CurveType.CATMULL_ROM,
  )
  _debug_draw.draw_arrow_curve(
    _make_curve_points(origin + row_gap * 2.0),
    Color.GREEN,
    DebugDraw3DNode.CurveType.ROUND_CORNER,
  )
  _debug_draw.draw_arrow_curve(
    _make_curve_points(origin + row_gap * 3.0),
    Color.CYAN,
    DebugDraw3DNode.CurveType.CLOSED_ROUND_CORNER,
  )
  _debug_draw.draw_arrow_curve(
    _make_curve_points(origin + row_gap * 4.0),
    Color.YELLOW,
    DebugDraw3DNode.CurveType.BEZIER,
    DebugDraw3DNode.ArrowPointType.PRISMATIC,
  )
  _debug_draw.draw_arrow_curve(
    _make_curve_points(origin + row_gap * 5.0),
    Color.MAGENTA,
    DebugDraw3DNode.CurveType.BEZIER,
    DebugDraw3DNode.ArrowPointType.CIRCLE,
  )
  _debug_draw.draw_arrow_curve(
    _make_curve_points(origin + row_gap * 6.0),
    Color.ORANGE,
    DebugDraw3DNode.CurveType.BEZIER,
    DebugDraw3DNode.ArrowPointType.TRIANGLE,
    DebugDraw3DNode.LineStyle.DASH,
  )
  _debug_draw.draw_arrow_curve(
    _make_curve_points(origin + row_gap * 7.0),
    Color.PINK,
    DebugDraw3DNode.CurveType.BEZIER,
    DebugDraw3DNode.ArrowPointType.TRIANGLE,
    DebugDraw3DNode.LineStyle.DEFAULT,
    true,
  )


func _setup_origin_axes_labels() -> void:
  _origin_axes_labels = Node3D.new()
  _origin_axes_labels.name = "OriginAxesLabels"
  add_child(_origin_axes_labels)

  _add_axis_label("XAxisLabel", "X", Vector3(1.4, 0.0, 0.0), Color.RED)
  _add_axis_label("YAxisLabel", "Y", Vector3(0.0, 1.4, 0.0), Color.GREEN)
  _add_axis_label("ZAxisLabel", "Z", Vector3(0.0, 0.0, 1.4), Color.BLUE)


func _setup_draw_line_labels() -> void:
  _demo_labels = Node3D.new()
  _demo_labels.name = "DrawLineLabels"
  add_child(_demo_labels)

  var origin := Vector3(1.0, 0.1, -1.0)
  var row_gap := Vector3(0.0, 0.0, -1.0)
  var label_anchor_offset := Vector3(-0.1, 0.0, 0.0)

  _add_demo_label("DrawLineTitle", "draw_line", origin + Vector3(-0.1, 0.0, 0.5))
  _add_demo_label("DrawLineDefaultLabel", "style=DEFAULT", origin + label_anchor_offset)
  _add_demo_label("DrawLineDashLabel", "style=DASH", origin + row_gap + label_anchor_offset)
  _add_demo_label("DrawLineDotLabel", "style=DOT", origin + row_gap * 2.0 + label_anchor_offset)
  _add_demo_label("DrawLineOverheadLabel", "overhead=true", origin + row_gap * 3.0 + label_anchor_offset)


func _setup_draw_polyline_labels() -> void:
  var draw_line_end_x := 3.0
  var origin := Vector3(draw_line_end_x + DEMO_COLUMN_GAP, 0.1, -1.0)
  var row_gap := Vector3(0.0, 0.0, -1.0)
  var label_anchor_offset := Vector3(-0.1, 0.0, 0.0)

  _add_demo_label("DrawPolylineTitle", "draw_polyline", origin + Vector3(-0.1, 0.0, 0.5))
  _add_demo_label("DrawPolylineDefaultLabel", "style=DEFAULT", origin + label_anchor_offset)
  _add_demo_label("DrawPolylineDashLabel", "style=DASH", origin + row_gap + label_anchor_offset)
  _add_demo_label("DrawPolylineDotLabel", "style=DOT", origin + row_gap * 2.0 + label_anchor_offset)
  _add_demo_label("DrawPolylineOverheadLabel", "overhead=true", origin + row_gap * 3.0 + label_anchor_offset)


func _setup_draw_curve_labels() -> void:
  var draw_polyline_end_x := 6.8
  var origin := Vector3(draw_polyline_end_x + DEMO_COLUMN_GAP, 0.1, -1.0)
  var row_gap := Vector3(0.0, 0.0, -1.0)
  var label_anchor_offset := Vector3(-0.1, 0.0, 0.0)

  _add_demo_label("DrawCurveTitle", "draw_curve", origin + Vector3(-0.1, 0.0, 0.5))
  _add_demo_label("DrawCurveBezierLabel", "curve_type=BEZIER", origin + label_anchor_offset)
  _add_demo_label("DrawCurveCatmullRomLabel", "curve_type=CATMULL_ROM", origin + row_gap + label_anchor_offset)
  _add_demo_label("DrawCurveRoundCornerLabel", "curve_type=ROUND_CORNER", origin + row_gap * 2.0 + label_anchor_offset)
  _add_demo_label("DrawCurveClosedRoundCornerLabel", "curve_type=CLOSED_ROUND_CORNER", origin + row_gap * 3.0 + label_anchor_offset)
  _add_demo_label("DrawCurveLinesLabel", "curve_type=LINES", origin + row_gap * 4.0 + label_anchor_offset)
  _add_demo_label("DrawCurveHermiteLabel", "curve_type=HERMITE", origin + row_gap * 5.0 + label_anchor_offset)


func _setup_draw_arrow_labels() -> void:
  var draw_curve_end_x := 10.6
  var origin := Vector3(draw_curve_end_x + DEMO_COLUMN_GAP, 0.1, -1.0)
  var row_gap := Vector3(0.0, 0.0, -1.0)
  var label_anchor_offset := Vector3(-0.1, 0.0, 0.0)

  _add_demo_label("DrawArrowTitle", "draw_arrow", origin + Vector3(-0.1, 0.0, 0.5))
  _add_demo_label("DrawArrowNoneLabel", "point_type=NONE", origin + label_anchor_offset)
  _add_demo_label("DrawArrowTriangleLabel", "point_type=TRIANGLE", origin + row_gap + label_anchor_offset)
  _add_demo_label("DrawArrowPrismaticLabel", "point_type=PRISMATIC", origin + row_gap * 2.0 + label_anchor_offset)
  _add_demo_label("DrawArrowCircleLabel", "point_type=CIRCLE", origin + row_gap * 3.0 + label_anchor_offset)
  _add_demo_label("DrawArrowDashLabel", "style=DASH", origin + row_gap * 4.0 + label_anchor_offset)
  _add_demo_label("DrawArrowDotLabel", "style=DOT", origin + row_gap * 5.0 + label_anchor_offset)
  _add_demo_label("DrawArrowOverheadLabel", "overhead=true", origin + row_gap * 6.0 + label_anchor_offset)


func _setup_draw_arrow_curve_labels() -> void:
  var draw_arrow_end_x := 14.6
  var origin := Vector3(draw_arrow_end_x + DEMO_COLUMN_GAP, 0.1, -1.0)
  var row_gap := Vector3(0.0, 0.0, -1.0)
  var label_anchor_offset := Vector3(-0.1, 0.0, 0.0)

  _add_demo_label("DrawArrowCurveTitle", "draw_arrow_curve", origin + Vector3(-0.1, 0.0, 0.5))
  _add_demo_label("DrawArrowCurveBezierLabel", "curve_type=BEZIER", origin + label_anchor_offset)
  _add_demo_label("DrawArrowCurveCatmullRomLabel", "curve_type=CATMULL_ROM", origin + row_gap + label_anchor_offset)
  _add_demo_label("DrawArrowCurveRoundCornerLabel", "curve_type=ROUND_CORNER", origin + row_gap * 2.0 + label_anchor_offset)
  _add_demo_label("DrawArrowCurveClosedRoundCornerLabel", "curve_type=CLOSED_ROUND_CORNER", origin + row_gap * 3.0 + label_anchor_offset)
  _add_demo_label("DrawArrowCurvePrismaticLabel", "point_type=PRISMATIC", origin + row_gap * 4.0 + label_anchor_offset)
  _add_demo_label("DrawArrowCurveCircleLabel", "point_type=CIRCLE", origin + row_gap * 5.0 + label_anchor_offset)
  _add_demo_label("DrawArrowCurveDashLabel", "style=DASH", origin + row_gap * 6.0 + label_anchor_offset)
  _add_demo_label("DrawArrowCurveOverheadLabel", "overhead=true", origin + row_gap * 7.0 + label_anchor_offset)


func _make_polyline_points(origin: Vector3) -> PackedVector3Array:
  return PackedVector3Array(
    [
      origin,
      origin + Vector3(0.45, 0.45, 0.0),
      origin + Vector3(0.9, 0.0, 0.0),
      origin + Vector3(1.35, 0.45, 0.0),
      origin + Vector3(1.8, 0.0, 0.0),
    ],
  )


func _make_curve_points(origin: Vector3) -> PackedVector3Array:
  return PackedVector3Array(
    [
      origin,
      origin + Vector3(0.45, 0.65, 0.0),
      origin + Vector3(1.35, -0.35, 0.0),
      origin + Vector3(1.8, 0.3, 0.0),
    ],
  )


func _add_axis_label(label_name: String, text: String, label_position: Vector3, color: Color) -> Label3D:
  var label := _new_label(label_name, text, label_position)
  label.modulate = color
  _origin_axes_labels.add_child(label)
  return label


func _add_demo_label(label_name: String, text: String, label_position: Vector3) -> Label3D:
  var label := _new_label(label_name, text, label_position)
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  _demo_labels.add_child(label)
  return label


func _new_label(label_name: String, text: String, label_position: Vector3) -> Label3D:
  var label := Label3D.new()
  label.name = label_name
  label.text = text
  label.position = label_position
  label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
  label.fixed_size = false
  label.no_depth_test = false
  label.shaded = false
  label.double_sided = true
  label.font_size = LABEL_FONT_SIZE
  label.pixel_size = LABEL_PIXEL_SIZE
  label.modulate = Color(0.86, 0.94, 1.0, 1.0)
  label.outline_modulate = Color(0.02, 0.04, 0.06, 1.0)
  label.outline_size = 8
  return label
