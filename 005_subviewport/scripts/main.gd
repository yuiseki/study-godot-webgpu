extends Control


func _ready() -> void:
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 540)
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(root)

	var marker := ColorRect.new()
	marker.color = Color(0.16, 0.62, 0.82, 1.0)
	marker.custom_minimum_size = Vector2(220, 120)
	marker.position = Vector2(120, 100)
	root.add_child(marker)

	var badge := Label.new()
	badge.text = "005_subviewport"
	badge.position = Vector2(140, 140)
	root.add_child(badge)

	print("005_subviewport ready")
