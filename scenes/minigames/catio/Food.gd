extends Area2D

var food_value := 5.0
var consumed := false

func consume() -> bool:
	if consumed:
		return false
	consumed = true
	queue_free()
	return true

const OUTLINE := Color("#65372F")
const FOOD_PALETTES := [
	[Color("#F29A62"), Color("#FFD6A8"), Color("#F2A5B5")], # рыбка/лакомство
	[Color("#FFF0D8"), Color("#A9C8E3"), Color("#65372F")], # молочко
	[Color("#F6CF79"), Color("#F29A62"), Color("#65372F")], # сыр
	[Color("#F2A5B5"), Color("#FFF0D8"), Color("#A7654F")]  # печенье
]

func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _make_food_texture(randi() % FOOD_PALETTES.size())
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	# Еда немного подпрыгивает, но остаётся чёткой пиксельной.
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -2.0, 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 2.0, 0.45).set_trans(Tween.TRANS_SINE)

func _make_food_texture(kind: int) -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var palette: Array = FOOD_PALETTES[kind]
	# Пиксельная форма лакомства с контуром, размер исходника ровно 32x32.
	for y in range(8, 24, 4):
		for x in range(8, 24, 4):
			image.fill_rect(Rect2i(x, y, 4, 4), palette[0])
	image.fill_rect(Rect2i(12, 4, 8, 4), OUTLINE)
	image.fill_rect(Rect2i(8, 8, 16, 4), OUTLINE)
	image.fill_rect(Rect2i(4, 12, 24, 8), OUTLINE)
	image.fill_rect(Rect2i(8, 20, 16, 4), OUTLINE)
	image.fill_rect(Rect2i(12, 24, 8, 4), OUTLINE)
	image.fill_rect(Rect2i(8, 12, 16, 8), palette[0])
	image.fill_rect(Rect2i(12, 8, 8, 4), palette[1])
	image.fill_rect(Rect2i(12, 16, 4, 4), palette[1])
	image.fill_rect(Rect2i(20, 12, 4, 4), palette[2])
	return ImageTexture.create_from_image(image)
