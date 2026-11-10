extends Area2D

var mass := 20.0
var base_speed := 250.0
var move_direction := Vector2.RIGHT
var can_move := true

const PIXEL := 4.0
const OUTLINE := Color("#65372F")
const FUR := Color("#F29A62")
const LIGHT_FUR := Color("#FFD6A8")
const PINK := Color("#F2A5B5")

func _ready() -> void:
	add_to_group("cats")
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(-16, -16))
	# Котик в пиксельном стиле: все элементы кратны 4 px (спрайт 32x32).
	var pixels := [
		[Vector2(8, 0), Vector2(8, 4), OUTLINE],
		[Vector2(12, 4), Vector2(8, 4), OUTLINE],
		[Vector2(4, 8), Vector2(24, 4), OUTLINE],
		[Vector2(0, 12), Vector2(32, 12), OUTLINE],
		[Vector2(4, 24), Vector2(24, 4), OUTLINE],
		[Vector2(8, 28), Vector2(16, 4), OUTLINE],
		[Vector2(8, 8), Vector2(16, 4), FUR],
		[Vector2(4, 12), Vector2(24, 12), FUR],
		[Vector2(8, 24), Vector2(16, 4), FUR],
		[Vector2(8, 4), Vector2(4, 4), LIGHT_FUR],
		[Vector2(20, 4), Vector2(4, 4), LIGHT_FUR],
		[Vector2(8, 16), Vector2(4, 4), LIGHT_FUR],
		[Vector2(20, 16), Vector2(4, 4), LIGHT_FUR],
		[Vector2(12, 16), Vector2(8, 4), PINK],
		[Vector2(8, 12), Vector2(4, 4), OUTLINE],
		[Vector2(20, 12), Vector2(4, 4), OUTLINE]
	]
	for pixel in pixels:
		draw_rect(Rect2(pixel[0], pixel[1]), pixel[2])
	# Блики на глазах и маленький носик.
	draw_rect(Rect2(9, 13, 2, 2), Color("#FFF0D8"))
	draw_rect(Rect2(21, 13, 2, 2), Color("#FFF0D8"))
	draw_rect(Rect2(15, 20, 2, 2), OUTLINE)

func _input(event: InputEvent) -> void:
	if not can_move:
		return
	var direction := get_global_mouse_position() - global_position
	if event is InputEventScreenTouch and event.pressed:
		if direction.length() > 10.0:
			move_direction = direction.normalized()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if direction.length() > 10.0:
			move_direction = direction.normalized()
	elif event is InputEventScreenDrag:
		if direction.length() > 10.0:
			move_direction = direction.normalized()

func _physics_process(delta: float) -> void:
	if not can_move:
		return
	var current_speed := maxf(90.0, base_speed / (1.0 + sqrt(mass / 100.0)))
	global_position += move_direction * current_speed * delta
	var radius := 20.0 * scale.x
	global_position.x = clampf(global_position.x, -1000.0 + radius, 1000.0 - radius)
	global_position.y = clampf(global_position.y, -1000.0 + radius, 1000.0 - radius)

func grow(amount: float) -> void:
	mass += amount
	var target_scale := 1.0 + mass / 100.0
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(target_scale, target_scale), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func reset_mass() -> void:
	mass = 20.0
	scale = Vector2.ONE

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("food"):
		grow(area.food_value)
		area.queue_free()
