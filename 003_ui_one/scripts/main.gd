extends Control


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420, 120)
	add_child(panel)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = "003_ui_one\nWebGPU UI smoke test"
	label.custom_minimum_size = Vector2(380, 84)
	panel.add_child(label)

	print("003_ui_one ready")
