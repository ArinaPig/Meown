extends Area2D
var food_value = 5.0

func _ready():
	var colors = [Color(1, 0.2, 0.2), Color(0.2, 1, 0.2), Color(1, 1, 0.2)]
	var c = colors[randi() % colors.size()]
	var sprite = Sprite2D.new()
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(c)
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)
