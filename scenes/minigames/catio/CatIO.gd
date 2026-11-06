extends Node2D

@export var food_scene: PackedScene 
@onready var ysort = $YSort
@onready var player = $YSort/Cat
@onready var camera = $YSort/Camera2D
@onready var food_timer = $FoodTimer

var max_food = 150

func _ready():
	food_timer.timeout.connect(_on_FoodTimer_timeout)
	if not food_scene:
		food_scene = load("res://scenes/minigames/catio/Food.tscn")
	
	for i in range(50):
		spawn_food()

func _process(delta):
	camera.global_position = player.global_position
	var target_zoom_val = 0.6 + (player.mass / 400.0)
	camera.zoom = camera.zoom.lerp(Vector2(target_zoom_val, target_zoom_val), delta * 2.0)

func spawn_food():
	if ysort.get_child_count() >= max_food: return
	var food = food_scene.instantiate()
	food.add_to_group("food")
	food.position = Vector2(randf_range(-900, 900), randf_range(-900, 900))
	ysort.add_child(food)

func _on_FoodTimer_timeout():
	spawn_food()
