extends Node2D

@export var food_scene: PackedScene
@export var cat_scene: PackedScene
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
const BOT_COLORS := [
	Color("#F2A5B5"), Color("#A9C8E3"), Color("#B8C98A"),
	Color("#C4A4D8"), Color("#FFD6A8"), Color("#E58E82")
]
const BOT_NAMES := ["Пончик", "Луна", "Милки", "Персик", "Плюша", "Кекс"]

var max_food := 180
var elapsed_time := 0.0
var leaderboard_label: Label
var game_over := false

func _ready() -> void:
	food_timer.wait_time = 0.30
	food_timer.timeout.connect(_on_food_timer_timeout)
	if not food_scene:
		food_scene = load("res://scenes/minigames/catio/Food.tscn")
	if not cat_scene:
		cat_scene = load("res://scenes/minigames/catio/Cat.tscn")
	camera.zoom = Vector2.ONE * 1.3
	# Keep the camera view inside the pink arena so the outer clear-color area is never exposed.
	camera.limit_left = -1000
	camera.limit_top = -1000
	camera.limit_right = 1000
	camera.limit_bottom = 1000
	_setup_arena()
	_setup_hud()
	_spawn_bots()
	for i in range(90):
		spawn_food()

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if bool(player.get("is_eaten")):
		if not game_over:
			game_over = true
			food_timer.stop()
			time_label.text = "ТЫ ПРОИГРАЛА"
			mass_label.text = "МАССА  %d" % int(float(player.get("mass")))
			return
	if game_over:
		return
	elapsed_time += delta
	if is_instance_valid(camera):
		camera.global_position = camera.global_position.lerp(player.global_position, min(delta * 7.0, 1.0))
	# Keep the cat prominent at the start; zoom out noticeably as its mass grows.
	var player_mass: float = float(player.get("mass"))
	var target_zoom: float = clampf(1.30 - (player_mass / 1500.0), 0.50, 1.30)
	camera.zoom = camera.zoom.lerp(Vector2.ONE * target_zoom, min(delta * 2.5, 1.0))
	time_label.text = "ВРЕМЯ  %02d:%02d" % [int(elapsed_time) / 60, int(elapsed_time) % 60]
	mass_label.text = "МАССА  %d" % int(float(player.get("mass")))
	_update_leaderboard()

func _setup_arena() -> void:
	var background := $Background as Polygon2D
	background.color = CAFE_BG
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
	var panel := PanelContainer.new()
	panel.name = "Leaderboard"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-166, 58)
	panel.custom_minimum_size = Vector2(150, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = CAFE_PANEL
	style.border_color = CAFE_PINK
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	$UI/UIRoot.add_child(panel)
	leaderboard_label = Label.new()
	leaderboard_label.add_theme_color_override("font_color", CAFE_BROWN)
	leaderboard_label.add_theme_font_size_override("font_size", 11)
	leaderboard_label.text = "ТОП КОТИКОВ"
	panel.add_child(leaderboard_label)

	var map_button := Button.new()
	map_button.text = "НА КАРТУ"
	map_button.position = Vector2(16, 730)
	map_button.size = Vector2(118, 42)
	map_button.add_theme_font_size_override("font_size", 13)
	map_button.add_theme_color_override("font_color", CAFE_BROWN)
	var map_style := StyleBoxFlat.new()
	map_style.bg_color = CAFE_PANEL
	map_style.border_color = CAFE_PINK
	map_style.set_border_width_all(2)
	map_style.set_corner_radius_all(8)
	map_button.add_theme_stylebox_override("normal", map_style)
	map_button.add_theme_stylebox_override("hover", map_style)
	map_button.add_theme_stylebox_override("pressed", map_style)
	map_button.pressed.connect(_return_to_map)
	$UI/UIRoot.add_child(map_button)

func _spawn_bots() -> void:
	for i in range(BOT_NAMES.size()):
		var bot: Area2D = cat_scene.instantiate() as Area2D
		bot.set("is_player", false)
		bot.set("bot_name", BOT_NAMES[i])
		bot.set("body_color", BOT_COLORS[i])
		bot.set("mass", randf_range(18.0, 55.0))
		bot.position = Vector2(randf_range(-780, 780), randf_range(-780, 780))
		ysort.add_child(bot)

func _update_leaderboard() -> void:
	if not is_instance_valid(leaderboard_label):
		return
	var cats: Array[Node] = []
	for cat_node in get_tree().get_nodes_in_group("cats"):
		if is_instance_valid(cat_node) and not cat_node.is_queued_for_deletion():
			cats.append(cat_node)
	cats.sort_custom(func(a: Node, b: Node) -> bool:
		return float(a.get("mass")) > float(b.get("mass"))
	)
	var lines: PackedStringArray = ["ТОП КОТИКОВ"]
	for i in range(mini(5, cats.size())):
		var cat: Area2D = cats[i] as Area2D
		var cat_display_name: String = "Ты" if cat == player else str(cat.get("bot_name"))
		lines.append("%d. %s  %d" % [i + 1, cat_display_name, int(cat.get("mass"))])
	leaderboard_label.text = "\n".join(lines)

func spawn_food() -> void:
	if get_tree().get_nodes_in_group("food").size() >= max_food:
		return
	var food: Area2D = food_scene.instantiate() as Area2D
	food.add_to_group("food")
	food.position = Vector2(randf_range(-900, 900), randf_range(-900, 900))
	ysort.add_child(food)

func _on_food_timer_timeout() -> void:
	spawn_food()


func _return_to_map() -> void:
	GameState.return_to_map()
