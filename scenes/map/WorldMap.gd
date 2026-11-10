extends Control

const MAP_ASSET_LAYER_SCRIPT := preload("res://scenes/map/MapAssetLayer.gd")

const CAFE_BG := Color("#FAD2B8")
const CAFE_PANEL := Color("#FFF0D8")
const CAFE_BROWN := Color("#65372F")
const CAFE_MUTED := Color("#A7654F")
const CAFE_PINK := Color("#F2A5B5")
const CAFE_SAGE := Color("#BDD2AA")
const CAFE_BLUE := Color("#A9C8E3")
const CAFE_YELLOW := Color("#F6CF79")

var map_asset_layer: Node
var status_label: Label
var shop_button: Button
var home_button: Button
var party_button: Button
var transition_overlay: ColorRect
var _transitioning: bool = false
var _button_tweens: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_asset_layer = MAP_ASSET_LAYER_SCRIPT.new()
	map_asset_layer.name = "MapAssetLayer"
	add_child(map_asset_layer)
	_build_interface()
	_create_transition_overlay()
	queue_redraw()

func _draw() -> void:
	if map_asset_layer != null and bool(map_asset_layer.call("is_asset_pack_active")):
		return

	var size := get_rect().size
	if size.x <= 0.0:
		size = Vector2(480.0, 800.0)
	draw_rect(Rect2(Vector2.ZERO, size), CAFE_BG)

	# Soft grass patches and tiny pixel flowers.
	for patch in [Rect2(12, 155, 105, 82), Rect2(330, 180, 130, 88), Rect2(18, 430, 92, 95), Rect2(350, 535, 112, 110)]:
		draw_rect(patch, Color("#F3C4A9"))
	for point in [Vector2(35, 180), Vector2(430, 210), Vector2(42, 490), Vector2(420, 610), Vector2(245, 720), Vector2(285, 250), Vector2(300, 565), Vector2(90, 590), Vector2(355, 720)]:
		_draw_flower(point)

	# A winding path connects the three places.
	var path_points := PackedVector2Array([
		Vector2(125, 295), Vector2(210, 335), Vector2(315, 405),
		Vector2(285, 475), Vector2(215, 530), Vector2(155, 625)
	])
	for i in range(path_points.size() - 1):
		draw_line(path_points[i], path_points[i + 1], Color("#E9B88F"), 30.0, true)
		draw_line(path_points[i], path_points[i + 1], Color("#F7DCC0"), 22.0, true)
	for i in range(1, 15):
		var t := float(i) / 15.0
		var p := Vector2(125, 295).lerp(Vector2(315, 405), t)
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color("#D9A77F"))

	_draw_shop(Vector2(125, 285))
	_draw_house(Vector2(350, 430))
	_draw_party(Vector2(155, 625))
	_draw_tree(Vector2(48, 325))
	_draw_tree(Vector2(430, 330))
	_draw_tree(Vector2(385, 690))
	_draw_tree(Vector2(40, 690))
	_draw_bush(Vector2(275, 245))
	_draw_bush(Vector2(300, 575))
	_draw_bush(Vector2(75, 555))
	_draw_lamp(Vector2(235, 375))
	_draw_lamp(Vector2(245, 545))
	_draw_bench(Vector2(315, 655))
	_draw_resident_cat(Vector2(250, 270), Color("#F2B36F"), Color("#FFF0D8"))
	_draw_resident_cat(Vector2(405, 535), Color("#A9C8E3"), Color("#FFF0D8"))
	_draw_resident_cat(Vector2(285, 700), Color("#E58E82"), Color("#FFF0D8"))
	_draw_pawprints(Vector2(205, 390), 4, Vector2(13, 15))
	_draw_pawprints(Vector2(260, 505), 3, Vector2(-12, 13))

func _draw_shop(center: Vector2) -> void:
	# Awning, shop body, door and display window.
	draw_rect(Rect2(center + Vector2(-55, -34), Vector2(110, 72)), Color("#FFF0D8"))
	draw_rect(Rect2(center + Vector2(-61, -43), Vector2(122, 20)), CAFE_BROWN)
	for i in range(6):
		var awning_color: Color = CAFE_PINK if i % 2 == 0 else Color("#FFF0D8")
		draw_rect(Rect2(center + Vector2(-59 + i * 20, -41), Vector2(20, 17)), awning_color)
	draw_rect(Rect2(center + Vector2(-45, -8), Vector2(30, 28)), CAFE_BLUE)
	draw_rect(Rect2(center + Vector2(18, -12), Vector2(23, 50)), Color("#D99A72"))
	draw_rect(Rect2(center + Vector2(23, 8), Vector2(4, 4)), CAFE_YELLOW)
	draw_rect(Rect2(center + Vector2(-9, -59), Vector2(18, 12)), CAFE_YELLOW)
	draw_rect(Rect2(center + Vector2(-3, -56), Vector2(6, 6)), CAFE_BROWN)

func _draw_house(center: Vector2) -> void:
	draw_rect(Rect2(center + Vector2(-53, -23), Vector2(106, 65)), Color("#FFF0D8"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-65, -22), center + Vector2(0, -72),
		center + Vector2(65, -22)
	]), Color("#E58E82"))
	draw_rect(Rect2(center + Vector2(-37, -5), Vector2(25, 25)), CAFE_BLUE)
	draw_rect(Rect2(center + Vector2(13, -9), Vector2(25, 51)), Color("#D99A72"))
	draw_rect(Rect2(center + Vector2(29, 15), Vector2(4, 4)), CAFE_YELLOW)
	# Cat-ear detail on the roof.
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-18, -57), center + Vector2(-13, -76), center + Vector2(-3, -62)
	]), CAFE_PINK)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(3, -62), center + Vector2(13, -76), center + Vector2(18, -57)
	]), CAFE_PINK)

func _draw_party(center: Vector2) -> void:
	# Picnic table and bunting.
	draw_rect(Rect2(center + Vector2(-62, 2), Vector2(124, 35)), Color("#D99A72"))
	draw_rect(Rect2(center + Vector2(-54, 36), Vector2(10, 20)), CAFE_BROWN)
	draw_rect(Rect2(center + Vector2(44, 36), Vector2(10, 20)), CAFE_BROWN)
	draw_line(center + Vector2(-68, -55), center + Vector2(68, -55), CAFE_BROWN, 3.0)
	for i in range(6):
		var x := center.x - 58 + i * 23
		var flag_color: Color = [CAFE_PINK, CAFE_BLUE, CAFE_YELLOW][i % 3]
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, center.y - 53), Vector2(x + 17, center.y - 53),
			Vector2(x + 8, center.y - 34)
		]), flag_color)
	# Cake on the table.
	draw_rect(Rect2(center + Vector2(-18, -13), Vector2(36, 18)), Color("#F2A5B5"))
	draw_rect(Rect2(center + Vector2(-18, -17), Vector2(36, 6)), CAFE_PANEL)
	draw_rect(Rect2(center + Vector2(-2, -27), Vector2(4, 10)), CAFE_YELLOW)

func _draw_tree(center: Vector2) -> void:
	draw_rect(Rect2(center + Vector2(-5, 10), Vector2(10, 24)), Color("#A7654F"))
	draw_rect(Rect2(center + Vector2(-17, -7), Vector2(34, 24)), CAFE_SAGE)
	draw_rect(Rect2(center + Vector2(-11, -17), Vector2(22, 14)), Color("#AFC58F"))
	draw_rect(Rect2(center + Vector2(-4, -4), Vector2(5, 5)), Color("#F6E4B9"))


func _draw_bush(center: Vector2) -> void:
	# Small layered shrubs in the same chunky pixel style.
	draw_rect(Rect2(center + Vector2(-19, -2), Vector2(38, 15)), Color("#8FAE7E"))
	draw_rect(Rect2(center + Vector2(-13, -9), Vector2(26, 12)), CAFE_SAGE)
	draw_rect(Rect2(center + Vector2(-4, -13), Vector2(8, 7)), Color("#D7DDAA"))
	draw_rect(Rect2(center + Vector2(8, -4), Vector2(5, 5)), CAFE_PINK)

func _draw_lamp(center: Vector2) -> void:
	# Warm little street lamps beside the winding path.
	draw_rect(Rect2(center + Vector2(-2, -2), Vector2(5, 30)), CAFE_BROWN)
	draw_rect(Rect2(center + Vector2(-8, -11), Vector2(17, 12)), CAFE_BROWN)
	draw_rect(Rect2(center + Vector2(-5, -8), Vector2(11, 7)), CAFE_YELLOW)
	draw_rect(Rect2(center + Vector2(-10, 27), Vector2(21, 4)), CAFE_BROWN)

func _draw_bench(center: Vector2) -> void:
	draw_rect(Rect2(center + Vector2(-22, -5), Vector2(44, 7)), Color("#D99A72"))
	draw_rect(Rect2(center + Vector2(-22, -15), Vector2(44, 7)), Color("#E7B184"))
	draw_rect(Rect2(center + Vector2(-17, 2), Vector2(5, 12)), CAFE_BROWN)
	draw_rect(Rect2(center + Vector2(12, 2), Vector2(5, 12)), CAFE_BROWN)


func _draw_resident_cat(center: Vector2, fur: Color, muzzle: Color) -> void:
	# Tiny neighborhood cats, drawn as crisp pixel sprites.
	draw_rect(Rect2(center + Vector2(-10, -7), Vector2(20, 17)), CAFE_BROWN)
	draw_rect(Rect2(center + Vector2(-8, -11), Vector2(16, 17)), fur)
	draw_rect(Rect2(center + Vector2(-9, -16), Vector2(6, 8)), CAFE_BROWN)
	draw_rect(Rect2(center + Vector2(3, -16), Vector2(6, 8)), CAFE_BROWN)
	draw_rect(Rect2(center + Vector2(-7, -13), Vector2(4, 6)), fur)
	draw_rect(Rect2(center + Vector2(3, -13), Vector2(4, 6)), fur)
	draw_rect(Rect2(center + Vector2(-5, -6), Vector2(3, 3)), CAFE_BROWN)
	draw_rect(Rect2(center + Vector2(3, -6), Vector2(3, 3)), CAFE_BROWN)
	draw_rect(Rect2(center + Vector2(-3, 0), Vector2(6, 4)), muzzle)
	draw_rect(Rect2(center + Vector2(-2, 1), Vector2(3, 2)), CAFE_PINK)
	draw_rect(Rect2(center + Vector2(-8, 9), Vector2(5, 4)), CAFE_BROWN)
	draw_rect(Rect2(center + Vector2(3, 9), Vector2(5, 4)), CAFE_BROWN)
	draw_rect(Rect2(center + Vector2(8, -2), Vector2(5, 3)), fur)

func _draw_pawprints(start: Vector2, count: int, step: Vector2) -> void:
	for i in range(count):
		var p := start + step * float(i)
		draw_rect(Rect2(p + Vector2(-3, 0), Vector2(6, 5)), Color("#D6A27F"))
		draw_rect(Rect2(p + Vector2(-5, -4), Vector2(3, 3)), Color("#D6A27F"))
		draw_rect(Rect2(p + Vector2(-1, -6), Vector2(3, 3)), Color("#D6A27F"))
		draw_rect(Rect2(p + Vector2(3, -4), Vector2(3, 3)), Color("#D6A27F"))

func _draw_flower(point: Vector2) -> void:
	draw_rect(Rect2(point + Vector2(-2, -2), Vector2(4, 9)), CAFE_SAGE)
	draw_rect(Rect2(point + Vector2(-5, -5), Vector2(10, 5)), CAFE_PINK)
	draw_rect(Rect2(point + Vector2(-2, -7), Vector2(4, 4)), CAFE_YELLOW)

func _build_interface() -> void:
	var title := Label.new()
	title.text = "MEOWN"
	title.position = Vector2(0, 20)
	title.size = Vector2(480, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", CAFE_BROWN)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Подготовь самую уютную вечеринку!"
	subtitle.position = Vector2(20, 66)
	subtitle.size = Vector2(440, 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", CAFE_MUTED)
	add_child(subtitle)

	shop_button = _make_location_button("МАГАЗИН\nТри в ряд", Rect2(48, 350, 154, 62))
	shop_button.tooltip_text = "Магазин: собирай вкусности в игре «Три в ряд»."
	_setup_location_button(shop_button)
	shop_button.pressed.connect(_open_shop)
	add_child(shop_button)

	home_button = _make_location_button("ДОМИК\nПоиск предметов", Rect2(263, 485, 174, 62))
	home_button.tooltip_text = "Домик: помоги котику найти предметы для праздника."
	_setup_location_button(home_button)
	home_button.pressed.connect(_open_search)
	add_child(home_button)

	party_button = _make_location_button("ВЕЧЕРИНКА\nCat.io", Rect2(66, 680, 178, 58))
	party_button.tooltip_text = "Вечеринка: присоединяйся к котикам в Cat.io."
	_setup_location_button(party_button)
	party_button.pressed.connect(_open_party)
	add_child(party_button)

	status_label = Label.new()
	status_label.position = Vector2(20, 750)
	status_label.size = Vector2(440, 34)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", CAFE_BROWN)
	add_child(status_label)
	_refresh_locations()

func _make_location_button(caption: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = caption
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", CAFE_BROWN)
	button.add_theme_color_override("font_disabled_color", Color("#A98B7C"))
	button.add_theme_stylebox_override("normal", _button_style(CAFE_PANEL, CAFE_BROWN))
	button.add_theme_stylebox_override("hover", _button_style(Color("#FFF8EA"), CAFE_PINK))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#F6D6C7"), CAFE_BROWN))
	button.add_theme_stylebox_override("disabled", _button_style(Color("#E5CBBE"), Color("#B99D90")))
	button.focus_mode = Control.FOCUS_NONE
	return button

func _setup_location_button(button: Button) -> void:
	button.pivot_offset = button.size * 0.5
	button.mouse_entered.connect(_animate_button.bind(button, Vector2(1.035, 1.035), 0.12))
	button.mouse_exited.connect(_animate_button.bind(button, Vector2.ONE, 0.12))
	button.button_down.connect(_animate_button.bind(button, Vector2(0.96, 0.96), 0.07))
	button.button_up.connect(_on_location_button_released.bind(button))

func _on_location_button_released(button: Button) -> void:
	var target := Vector2(1.035, 1.035) if button.is_hovered() else Vector2.ONE
	_animate_button(button, target, 0.10)

func _animate_button(button: Button, target_scale: Vector2, duration: float) -> void:
	if not is_instance_valid(button):
		return

	var button_id := button.get_instance_id()
	if _button_tweens.has(button_id):
		var previous_tween: Variant = _button_tweens[button_id]
		if is_instance_valid(previous_tween):
			previous_tween.kill()

	var tween := create_tween()
	_button_tweens[button_id] = tween
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, duration)

func _create_transition_overlay() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.name = "TransitionOverlay"
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.color = CAFE_BROWN
	transition_overlay.modulate.a = 0.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.z_index = 100
	add_child(transition_overlay)

func _set_location_buttons_disabled(disabled: bool) -> void:
	shop_button.disabled = disabled
	home_button.disabled = disabled
	party_button.disabled = disabled

func _play_location_transition(game_key: String) -> void:
	if _transitioning:
		return

	_transitioning = true
	_set_location_buttons_disabled(true)

	var fade_out := create_tween()
	fade_out.set_trans(Tween.TRANS_SINE)
	fade_out.set_ease(Tween.EASE_IN)
	fade_out.tween_property(transition_overlay, "modulate:a", 1.0, 0.18)
	await fade_out.finished

	if GameState.start_minigame(game_key):
		return

	if game_key == "search":
		status_label.text = "Сцена поиска пока не подключена. Добавим её, когда Алиса будет готова."
	elif game_key == "catio":
		status_label.text = "Не удалось открыть Cat.io."
	else:
		status_label.text = "Не удалось открыть мини-игру."

	var fade_in := create_tween()
	fade_in.set_trans(Tween.TRANS_SINE)
	fade_in.set_ease(Tween.EASE_OUT)
	fade_in.tween_property(transition_overlay, "modulate:a", 0.0, 0.18)
	await fade_in.finished

	_transitioning = false
	_set_location_buttons_disabled(false)

func _button_style(fill: Color, outline: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _refresh_locations() -> void:
	shop_button.disabled = false
	home_button.disabled = false
	party_button.disabled = false
	if GameState.story_step >= GameState.StoryStep.PARTY:
		status_label.text = "Всё готово! Время веселиться!"
	elif GameState.story_step >= GameState.StoryStep.GATHER:
		status_label.text = "Магазин пройден! Теперь загляни домой."
	else:
		status_label.text = "Начни с магазина и собери угощения для праздника."

func _open_shop() -> void:
	_play_location_transition("shop")

func _open_search() -> void:
	_play_location_transition("search")

func _open_party() -> void:
	_play_location_transition("catio")
