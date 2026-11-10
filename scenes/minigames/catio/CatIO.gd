extends Node2D

@export var food_scene: PackedScene
@onready var ysort: Node2D = $YSort
@onready var player: Area2D = $YSort/Cat
@onready var camera: Camera2D = $YSort/Camera2D
@onready var food_timer: Timer = $FoodTimer
@onready var time_label: Label = $UI/UIRoot/TimeLabel
@onready var mass_label: Label = $UI/UIRoot/MassLabel

const CAFE_BG := Color("#FAD2B8")
const CAFE_PANEL := Color("#FFF0D8")
const CAFE_BROWN := Color("#65372F")
const CAFE_PINK := Color("#F2A5B5")
const CAFE_MUTED := Color("#A7654F")

var max_food := 150
var elapsed_time := 0.0

func _ready() -> void:
	food_timer.timeout.connect(_on_food_timer_timeout)
	if not food_scene:
		food_scene = load("res://scenes/minigames/catio/Food.tscn")
	_setup_arena()
	_setup_hud()
	for i in range(50):
		spawn_food()

func _process(delta: float) -> void:
	elapsed_time += delta
	camera.global_position = camera.global_position.lerp(player.global_position, min(delta * 7.0, 1.0))
	var target_zoom := 0.6 + (player.mass / 400.0)
	camera.zoom = camera.zoom.lerp(Vector2(target_zoom, target_zoom), min(delta * 2.0, 1.0))
	time_label.text = "ВРЕМЯ  %02d:%02d" % [int(elapsed_time) / 60, int(elapsed_time) % 60]
	mass_label.text = "МАССА  %d" % int(player.mass)

func _setup_arena() -> void:
	var background := $Background as Polygon2D
	background.color = CAFE_BG
	# Ненавязчивый пиксельный узор на большой игровой площадке.
	var pattern := Node2D.new()
	pattern.name = "CafePattern"
	pattern.z_index = -1
	pattern.draw.connect(func() -> void:
		for x in range(-960, 961, 96):
			for y in range(-960, 961, 96):
				pattern.draw_rect(Rect2(Vector2(x, y), Vector2(8, 8)), Color("#F6BFA9"))
	)
	background.add_child(pattern)

func _setup_hud() -> void:
	for label in [time_label, mass_label]:
		label.add_theme_color_override("font_color", CAFE_BROWN)
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_color_override("font_outline_color", CAFE_PANEL)
		label.add_theme_color_override("font_shadow_color", CAFE_MUTED)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 2)
	time_label.text = "ВРЕМЯ  00:00"
	mass_label.text = "МАССА  20"

func spawn_food() -> void:
	if ysort.get_child_count() >= max_food:
		return
	var food = food_scene.instantiate()
	food.add_to_group("food")
	food.position = Vector2(randf_range(-900, 900), randf_range(-900, 900))
	ysort.add_child(food)

func _on_food_timer_timeout() -> void:
	spawn_food()
