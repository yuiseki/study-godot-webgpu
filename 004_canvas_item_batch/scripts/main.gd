extends Node2D


func _ready() -> void:
	queue_redraw()
	print("004_canvas_item_batch ready")


func _draw() -> void:
	var cols := 16
	var rows := 9
	var cell := Vector2(48, 48)
	var origin := Vector2(96, 54)

	for y in range(rows):
		for x in range(cols):
			var rect := Rect2(origin + Vector2(x, y) * cell, cell - Vector2(6, 6))
			var shade := float(x + y) / float(cols + rows)
			draw_rect(rect, Color(0.12 + shade * 0.5, 0.22, 0.45 + shade * 0.35, 1.0), true)
			draw_rect(rect, Color(0.92, 0.94, 0.98, 0.85), false, 2.0)
