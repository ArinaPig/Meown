extends Area2D

@export var is_player := true
@export var bot_name := "Котик"
@export var body_color := Color("#F29A62")

var mass := 20.0
var base_speed := 250.0
var move_direction := Vector2.RIGHT
var can_move := true
var bot_target := Vector2.ZERO
var think_timer := 0.0
var is_eaten := false

const ARENA_LIMIT := 1000.0
const OUTLINE := Color("#65372F")
const CREAM := Color("#FFF0D8")
const PINK := Color("#F2A5B5")
const PIXEL := 2
const START_MASS := 20.0
const MAX_CAT_SCALE := 12.0

func _ready() -> void:
	add_to_group("cats")
	area_entered.connect(_on_area_entered)
	scale = Vector2.ONE * _scale_for_mass(mass)
	if not is_player:
		bot_target = global_position + Vector2(randf_range(-400, 400), randf_range(-400, 400))
	queue_redraw()

func _draw() -> void:
	# Keep the 32x32 avatar centered on the Area2D origin so it grows evenly.
	draw_set_transform(Vector2(-16.0, -16.0), 0.0, Vector2.ONE)
	# 32x32 pixel-art avatar: round Agar.io blob with tiny cat ears.
	var fur := body_color
	var light := fur.lightened(0.30)
		# Ears and outer circular silhouette, built from crisp 2px blocks.
	var rows := [
		[10, 12], [6, 20], [4, 24], [2, 28],
		[0, 32], [0, 32], [0, 32], [0, 32],
		[2, 28], [4, 24], [6, 20], [10, 12]
	]
	for row in range(rows.size()):
		var y: int = row * PIXEL + 4
		var x: int = int(rows[row][0])
		var width: int = int(rows[row][1])
		draw_rect(Rect2(x, y, width, PIXEL), OUTLINE)
	# Pixel ears on top of the round body.
	draw_rect(Rect2(4, 2, 8, 4), OUTLINE)
	draw_rect(Rect2(20, 2, 8, 4), OUTLINE)
	draw_rect(Rect2(6, 4, 4, 4), fur)
	draw_rect(Rect2(22, 4, 4, 4), fur)
	draw_rect(Rect2(8, 6, 2, 2), PINK)
	draw_rect(Rect2(22, 6, 2, 2), PINK)
	# Main body fill: inset rows make a rounded blob, not a square head.
	var fill_rows := [
		[8, 16], [4, 24], [2, 28], [2, 28],
		[2, 28], [4, 24], [6, 20], [8, 16]
	]
	for row in range(fill_rows.size()):
		draw_rect(Rect2(fill_rows[row][0], 8 + row * 2, fill_rows[row][1], 2), fur)
	# Cream muzzle and forehead patch.
	draw_rect(Rect2(10, 12, 12, 8), light)
	draw_rect(Rect2(12, 20, 8, 4), light)
	draw_rect(Rect2(14, 10, 4, 4), light)
	# Face: eyes, nose, smile and blush.
	draw_rect(Rect2(9, 15, 3, 4), OUTLINE)
	draw_rect(Rect2(20, 15, 3, 4), OUTLINE)
	draw_rect(Rect2(10, 15, 1, 1), CREAM)
	draw_rect(Rect2(21, 15, 1, 1), CREAM)
	draw_rect(Rect2(15, 19, 3, 2), PINK)
	draw_rect(Rect2(8, 20, 4, 2), PINK)
	draw_rect(Rect2(20, 20, 4, 2), PINK)
	draw_rect(Rect2(15, 22, 2, 2), OUTLINE)
	if is_player:
		draw_rect(Rect2(14, 0, 4, 2), Color("#F6CF79"))
		draw_rect(Rect2(12, 2, 8, 2), Color("#F6CF79"))

func _input(event: InputEvent) -> void:
	if not is_player or not can_move:
		return
	if event is InputEventScreenTouch and event.pressed:
		_update_player_direction()
	elif event is InputEventScreenDrag:
		_update_player_direction()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_update_player_direction()

func _update_player_direction() -> void:
	var direction := get_global_mouse_position() - global_position
	if direction.length() > 10.0:
		move_direction = direction.normalized()

func _physics_process(delta: float) -> void:
	if not can_move or is_eaten:
		return
	if not is_player:
		_bot_think(delta)
	var current_speed: float = maxf(85.0, base_speed / (1.0 + sqrt(mass / 100.0)))
	global_position += move_direction * current_speed * delta
	var radius: float = 20.0 * scale.x
	global_position.x = clampf(global_position.x, -ARENA_LIMIT + radius, ARENA_LIMIT - radius)
	global_position.y = clampf(global_position.y, -ARENA_LIMIT + radius, ARENA_LIMIT - radius)

func _bot_think(delta: float) -> void:
	think_timer -= delta
	if think_timer > 0.0:
		return
	think_timer = randf_range(0.18, 0.38)
	var nearest_food: Node2D
	var nearest_food_distance := INF
	var threat: Node2D
	var threat_distance := INF
	var prey: Node2D
	var prey_distance := INF
	for other_node in get_tree().get_nodes_in_group("cats"):
		var other: Area2D = other_node as Area2D
		if not is_instance_valid(other) or other == self or bool(other.get("is_eaten")):
			continue
		var distance: float = global_position.distance_to(other.global_position)
		if float(other.get("mass")) > mass * 1.18 and distance < threat_distance:
			threat = other
			threat_distance = distance
		elif mass > float(other.get("mass")) * 1.25 and distance < prey_distance:
			prey = other
			prey_distance = distance
	for food_node in get_tree().get_nodes_in_group("food"):
		var food: Node2D = food_node as Node2D
		if not is_instance_valid(food):
			continue
		var distance: float = global_position.distance_to(food.global_position)
		if distance < nearest_food_distance:
			nearest_food = food
			nearest_food_distance = distance
	if is_instance_valid(threat) and threat_distance < 260.0:
		move_direction = (global_position - threat.global_position).normalized()
	elif is_instance_valid(prey) and prey_distance < 220.0:
		move_direction = (prey.global_position - global_position).normalized()
	elif is_instance_valid(nearest_food) and nearest_food_distance < 420.0:
		move_direction = (nearest_food.global_position - global_position).normalized()
	elif global_position.distance_to(bot_target) < 50.0:
		bot_target = Vector2(randf_range(-850, 850), randf_range(-850, 850))
		move_direction = (bot_target - global_position).normalized()

func _scale_for_mass(value: float) -> float:
	# A square-root curve makes each pickup visibly affect the cat size.
	return clampf(sqrt(maxf(value, START_MASS) / START_MASS), 1.0, MAX_CAT_SCALE)

func grow(amount: float) -> void:
	if amount <= 0.0 or is_eaten:
		return
	mass += amount
	var target_scale: float = _scale_for_mass(mass)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * target_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func reset_mass() -> void:
	mass = START_MASS
	scale = Vector2.ONE * _scale_for_mass(mass)
	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if not is_instance_valid(area) or area.is_queued_for_deletion():
		return
	if is_eaten:
		return
	if area.is_in_group("food"):
		var value: float = float(area.get("food_value"))
		if area.has_method("consume"):
			if not bool(area.call("consume")):
				return
		else:
			area.queue_free()
		grow(value)
	elif area.is_in_group("cats") and area != self:
		if mass >= float(area.get("mass")) * 1.2 and not bool(area.get("is_eaten")):
			var eaten_mass: float = float(area.get("mass"))
			area.set("is_eaten", true)
			grow(eaten_mass * 0.75)
			if bool(area.get("is_player")):
				# Keep the player node alive so the HUD/camera never access a freed object.
				area.set("can_move", false)
				area.modulate = Color(1.0, 1.0, 1.0, 0.45)
			else:
				area.queue_free()
