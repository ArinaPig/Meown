extends Area2D

var mass = 20.0
var base_speed = 250.0
var move_direction = Vector2.RIGHT
var color = Color(0.9, 0.6, 0.2)
var can_move = true

func _ready():
	add_to_group("cats")
	area_entered.connect(_on_area_entered)

func _draw():
	draw_circle(Vector2.ZERO, 20, color)
	draw_colored_polygon(PackedVector2Array([Vector2(-15, -10), Vector2(-5, -25), Vector2(0, -15)]), color)
	draw_colored_polygon(PackedVector2Array([Vector2(15, -10), Vector2(5, -25), Vector2(0, -15)]), color)
	draw_circle(Vector2(-6, -2), 2, Color.BLACK)
	draw_circle(Vector2(6, -2), 2, Color.BLACK)

func _input(event):
	if not can_move: return
	var dir = get_global_mouse_position() - global_position
	if event is InputEventScreenTouch and event.pressed:
		if dir.length() > 10: move_direction = dir.normalized()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dir.length() > 10: move_direction = dir.normalized()
	elif event is InputEventScreenDrag:
		if dir.length() > 10: move_direction = dir.normalized()

func _physics_process(delta):
	if not can_move: return
	var current_speed = base_speed / (1.0 + sqrt(mass / 100.0))
	if current_speed < 90.0: current_speed = 90.0
	global_position += move_direction * current_speed * delta
	
	var radius = 20.0 * scale.x
	global_position.x = clamp(global_position.x, -1000.0 + radius, 1000.0 - radius)
	global_position.y = clamp(global_position.y, -1000.0 + radius, 1000.0 - radius)

func grow(amount):
	mass += amount
	scale = Vector2(1.0 + (mass / 100.0), 1.0 + (mass / 100.0))

func reset_mass():
	mass = 20.0
	scale = Vector2(1, 1)

func _on_area_entered(area):
	if area.is_in_group("food"):
		grow(area.food_value)
		area.queue_free()
