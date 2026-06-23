extends Node3D

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720


func _ready() -> void:
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(DESIGN_WIDTH * dpi_scale, DESIGN_HEIGHT * dpi_scale)
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
