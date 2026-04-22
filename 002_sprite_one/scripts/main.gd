extends Node2D


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _build_texture()
	sprite.centered = true
	sprite.position = get_viewport_rect().size * 0.5
	add_child(sprite)
	print("002_sprite_one ready")


func _build_texture() -> Texture2D:
	var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.91, 0.24, 0.35, 1.0))

	for x in range(8, 88):
		image.set_pixel(x, 8, Color(1.0, 0.92, 0.72, 1.0))
		image.set_pixel(x, 87, Color(1.0, 0.92, 0.72, 1.0))

	for y in range(8, 88):
		image.set_pixel(8, y, Color(1.0, 0.92, 0.72, 1.0))
		image.set_pixel(87, y, Color(1.0, 0.92, 0.72, 1.0))

	return ImageTexture.create_from_image(image)
