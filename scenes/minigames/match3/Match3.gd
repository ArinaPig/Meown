extends Control

# Match-3 для Meown — визуальная тема Kitten Cafe.
# Фишки: PNG-спрайты из res://assets/minigames/match3/.
# Управление: выберите две соседние фишки.

const BOARD_SIZE := 7
const SHOP_GOAL := 500
const TILE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/minigames/match3/fish.png"),
	preload("res://assets/minigames/match3/milk.png"),
	preload("res://assets/minigames/match3/cupcake.png"),
	preload("res://assets/minigames/match3/donut.png"),
	preload("res://assets/minigames/match3/cheese.png"),
	preload("res://assets/minigames/match3/chicken.png"),
	preload("res://assets/minigames/match3/yarn.png")
]
const TILE_COLORS: Array[Color] = [
	Color("#F6B39F"), # coral
	Color("#A9C8E3"), # blue
	Color("#FFF0D8"), # cream
	Color("#F2A5B5"), # pink
	Color("#F6CF79"), # yellow
	Color("#F29A62"), # orange
	Color("#BDD2AA")  # sage
]
const CAFE_BG := Color("#FAD2B8")
const CAFE_PANEL := Color("#FFF0D8")
const CAFE_BROWN := Color("#65372F")
const CAFE_MUTED := Color("#A7654F")

var board: Array = []
var tile_buttons: Array = []
var selected_cell := Vector2i(-1, -1)
var score := 0
var busy := false
var pointer_start_cell := Vector2i(-1, -1)
var pointer_active := false

var score_label: Label
var hint_label: Label
var grid: GridContainer

func _ready() -> void:
	_build_interface()
	_new_game()

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = CAFE_BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 12)
	margins.add_theme_constant_override("margin_right", 12)
	margins.add_theme_constant_override("margin_top", 24)
	margins.add_theme_constant_override("margin_bottom", 24)
	add_child(margins)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margins.add_child(layout)

	var title := Label.new()
	title.text = "Kitten Cafe"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", CAFE_BROWN)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Лавка вкусностей"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", CAFE_MUTED)
	layout.add_child(subtitle)

	var score_panel := PanelContainer.new()
	var score_style := StyleBoxFlat.new()
	score_style.bg_color = CAFE_PANEL
	score_style.border_color = CAFE_BROWN
	score_style.set_border_width_all(2)
	score_style.set_corner_radius_all(12)
	score_panel.add_theme_stylebox_override("panel", score_style)
	layout.add_child(score_panel)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", CAFE_BROWN)
	score_panel.add_child(score_label)

	hint_label = Label.new()
	hint_label.text = "Выбери две соседние фишки"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_color_override("font_color", CAFE_BROWN)
	layout.add_child(hint_label)

	var board_panel := PanelContainer.new()
	board_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var board_style := StyleBoxFlat.new()
	board_style.bg_color = CAFE_PANEL
	board_style.border_color = CAFE_BROWN
	board_style.set_border_width_all(3)
	board_style.set_corner_radius_all(16)
	board_style.content_margin_left = 6
	board_style.content_margin_right = 6
	board_style.content_margin_top = 6
	board_style.content_margin_bottom = 6
	board_panel.add_theme_stylebox_override("panel", board_style)
	layout.add_child(board_panel)

	grid = GridContainer.new()
	grid.columns = BOARD_SIZE
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	board_panel.add_child(grid)

	for y in range(BOARD_SIZE):
		var row_buttons: Array = []
		for x in range(BOARD_SIZE):
			var tile := Button.new()
			tile.custom_minimum_size = Vector2(55, 55)
			tile.expand_icon = true
			tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tile.pivot_offset = tile.custom_minimum_size / 2.0
			grid.add_child(tile)
			row_buttons.append(tile)
		tile_buttons.append(row_buttons)

	var restart := Button.new()
	restart.text = "Начать заново"
	restart.custom_minimum_size = Vector2(0, 48)
	restart.add_theme_font_size_override("font_size", 17)
	restart.add_theme_color_override("font_color", CAFE_BROWN)
	var restart_style := StyleBoxFlat.new()
	restart_style.bg_color = Color("#F2A5B5")
	restart_style.border_color = CAFE_BROWN
	restart_style.set_border_width_all(2)
	restart_style.set_corner_radius_all(12)
	restart.add_theme_stylebox_override("normal", restart_style)
	restart.add_theme_stylebox_override("hover", restart_style)
	restart.add_theme_stylebox_override("pressed", restart_style)
	restart.pressed.connect(_new_game)
	layout.add_child(restart)

	var map_button := Button.new()
	map_button.text = "На карту"
	map_button.custom_minimum_size = Vector2(0, 42)
	map_button.add_theme_font_size_override("font_size", 16)
	map_button.add_theme_color_override("font_color", CAFE_BROWN)
	map_button.pressed.connect(_return_to_map)
	layout.add_child(map_button)

func _new_game() -> void:
	score = 0
	selected_cell = Vector2i(-1, -1)
	board.clear()
	for y in range(BOARD_SIZE):
		var row: Array = []
		for x in range(BOARD_SIZE):
			row.append(randi() % TILE_TEXTURES.size())
		board.append(row)

	var initial_matches := _find_matches()
	var safety := 0
	while not initial_matches.is_empty() and safety < 100:
		for cell in initial_matches:
			board[cell.y][cell.x] = randi() % TILE_TEXTURES.size()
		initial_matches = _find_matches()
		safety += 1

	_refresh_board()
	_update_score()
	hint_label.text = "Выбери две соседние фишки"

func _input(event: InputEvent) -> void:
	var pressed := false
	var released := false
	var pointer_position := Vector2.ZERO

	if event is InputEventScreenTouch:
		pressed = event.pressed
		released = not event.pressed
		pointer_position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		released = not event.pressed
		pointer_position = event.position
	else:
		return

	if pressed:
		var cell := _cell_at_viewport_position(pointer_position)
		if cell.x >= 0 and not busy:
			pointer_start_cell = cell
			pointer_active = true
			get_viewport().set_input_as_handled()
	elif released and pointer_active:
		var start_cell := pointer_start_cell
		var end_cell := _cell_at_viewport_position(pointer_position)
		pointer_active = false
		pointer_start_cell = Vector2i(-1, -1)
		get_viewport().set_input_as_handled()

		if end_cell.x < 0:
			selected_cell = Vector2i(-1, -1)
			_refresh_board()
		elif start_cell == end_cell:
			_handle_tile_tap(end_cell)
		elif abs(start_cell.x - end_cell.x) + abs(start_cell.y - end_cell.y) == 1:
			selected_cell = Vector2i(-1, -1)
			_try_swap(start_cell, end_cell)
		else:
			selected_cell = end_cell
			hint_label.text = "Менять можно только соседние фишки"
			_refresh_board()

func _cell_at_viewport_position(viewport_position: Vector2) -> Vector2i:
	if grid == null:
		return Vector2i(-1, -1)
	var local_position := grid.get_global_transform_with_canvas().affine_inverse() * viewport_position
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var tile: Button = tile_buttons[y][x]
			if Rect2(tile.position, tile.size).has_point(local_position):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _handle_tile_tap(cell: Vector2i) -> void:
	if busy:
		return
	if selected_cell.x < 0:
		selected_cell = cell
	elif selected_cell == cell:
		selected_cell = Vector2i(-1, -1)
	elif abs(selected_cell.x - cell.x) + abs(selected_cell.y - cell.y) == 1:
		var first := selected_cell
		selected_cell = Vector2i(-1, -1)
		_try_swap(first, cell)
		return
	else:
		selected_cell = cell
	_refresh_board()

func _try_swap(first: Vector2i, second: Vector2i) -> void:
	if busy:
		return
	busy = true
	hint_label.text = "Меняем фишки..."
	var first_tile: Button = tile_buttons[first.y][first.x]
	var second_tile: Button = tile_buttons[second.y][second.x]
	var swap_out := create_tween().set_parallel(true)
	swap_out.tween_property(first_tile, "scale", Vector2(0.82, 0.82), 0.08)
	swap_out.tween_property(second_tile, "scale", Vector2(0.82, 0.82), 0.08)
	await swap_out.finished

	_swap_cells(first, second)
	_refresh_tile(first)
	_refresh_tile(second)
	var swap_in := create_tween().set_parallel(true)
	swap_in.tween_property(first_tile, "scale", Vector2.ONE, 0.12)
	swap_in.tween_property(second_tile, "scale", Vector2.ONE, 0.12)
	await swap_in.finished

	if _find_matches().is_empty():
		_swap_cells(first, second)
		_refresh_tile(first)
		_refresh_tile(second)
		var return_tween := create_tween().set_parallel(true)
		return_tween.tween_property(first_tile, "scale", Vector2(0.82, 0.82), 0.07)
		return_tween.tween_property(second_tile, "scale", Vector2(0.82, 0.82), 0.07)
		await return_tween.finished
		var restore_tween := create_tween().set_parallel(true)
		restore_tween.tween_property(first_tile, "scale", Vector2.ONE, 0.12)
		restore_tween.tween_property(second_tile, "scale", Vector2.ONE, 0.12)
		await restore_tween.finished
		hint_label.text = "Совпадений нет — попробуй другой ход"
		busy = false
		return

	await _resolve_board()

func _swap_cells(a: Vector2i, b: Vector2i) -> void:
	var temp = board[a.y][a.x]
	board[a.y][a.x] = board[b.y][b.x]
	board[b.y][b.x] = temp

func _find_matches() -> Array:
	var found := {}
	for y in range(BOARD_SIZE):
		var run_start := 0
		while run_start < BOARD_SIZE:
			var kind = board[y][run_start]
			var run_end := run_start + 1
			while run_end < BOARD_SIZE and board[y][run_end] == kind:
				run_end += 1
			if run_end - run_start >= 3:
				for x in range(run_start, run_end):
					found[Vector2i(x, y)] = true
			run_start = run_end

	for x in range(BOARD_SIZE):
		var run_start := 0
		while run_start < BOARD_SIZE:
			var kind = board[run_start][x]
			var run_end := run_start + 1
			while run_end < BOARD_SIZE and board[run_end][x] == kind:
				run_end += 1
			if run_end - run_start >= 3:
				for y in range(run_start, run_end):
					found[Vector2i(x, y)] = true
			run_start = run_end
	return found.keys()

func _resolve_board() -> void:
	var matches := _find_matches()
	while not matches.is_empty():
		score += matches.size() * 10
		var changed_cells := {}
		var vanish_tween := create_tween().set_parallel(true)
		for cell in matches:
			changed_cells[cell] = true
			var tile: Button = tile_buttons[cell.y][cell.x]
			vanish_tween.tween_property(tile, "scale", Vector2(0.15, 0.15), 0.16)
			vanish_tween.tween_property(tile, "modulate:a", 0.0, 0.16)
		await vanish_tween.finished

		var previous_board: Array = board.duplicate(true)
		for cell in matches:
			board[cell.y][cell.x] = -1
		_apply_gravity()
		_refill_board()

		# Меняем оформление только там, где содержимое клетки изменилось.
		for y in range(BOARD_SIZE):
			for x in range(BOARD_SIZE):
				if previous_board[y][x] != board[y][x]:
					changed_cells[Vector2i(x, y)] = true

		var appear_tween := create_tween().set_parallel(true)
		for cell in changed_cells:
			_refresh_tile(cell)
			var tile: Button = tile_buttons[cell.y][cell.x]
			tile.scale = Vector2(0.72, 0.72)
			tile.modulate.a = 0.0
			appear_tween.tween_property(tile, "scale", Vector2.ONE, 0.18)
			appear_tween.tween_property(tile, "modulate:a", 1.0, 0.18)
		await appear_tween.finished
		matches = _find_matches()

	if not _has_possible_move():
		_shuffle_board()
	_update_score()
	if score >= SHOP_GOAL and GameState.story_step == GameState.StoryStep.SHOP:
		GameState.complete_shop()
		hint_label.text = "Ура! Угощения собраны!"
		busy = true
		await get_tree().create_timer(1.0).timeout
		GameState.return_to_map()
		return

	hint_label.text = "Отлично! Собирай продукты дальше"
	busy = false

func _apply_gravity() -> void:
	for x in range(BOARD_SIZE):
		var write_y := BOARD_SIZE - 1
		for y in range(BOARD_SIZE - 1, -1, -1):
			if board[y][x] != -1:
				board[write_y][x] = board[y][x]
				write_y -= 1
		while write_y >= 0:
			board[write_y][x] = -1
			write_y -= 1

func _refill_board() -> void:
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			if board[y][x] == -1:
				board[y][x] = randi() % TILE_TEXTURES.size()

func _has_possible_move() -> bool:
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var origin := Vector2i(x, y)
			for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
				var neighbor: Vector2i = origin + direction
				if neighbor.x >= BOARD_SIZE or neighbor.y >= BOARD_SIZE:
					continue
				_swap_cells(origin, neighbor)
				var creates_match := not _find_matches().is_empty()
				_swap_cells(origin, neighbor)
				if creates_match:
					return true
	return false

func _shuffle_board() -> void:
	var values: Array[int] = []
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			values.append(int(board[y][x]))
	values.shuffle()
	var safety := 0
	while safety < 100:
		var index := 0
		for y in range(BOARD_SIZE):
			for x in range(BOARD_SIZE):
				board[y][x] = values[index]
				index += 1
		if _find_matches().is_empty() and _has_possible_move():
			break
		values.shuffle()
		safety += 1
	_refresh_board()
	hint_label.text = "Фишки перемешаны — появились новые ходы!"

func _refresh_tile(cell: Vector2i) -> void:
	var kind: int = board[cell.y][cell.x]
	var tile: Button = tile_buttons[cell.y][cell.x]
	tile.text = ""
	tile.icon = TILE_TEXTURES[kind]
	var style := StyleBoxFlat.new()
	style.bg_color = TILE_COLORS[kind]
	style.set_corner_radius_all(9)
	style.set_border_width_all(1)
	style.border_color = CAFE_BROWN
	if selected_cell == cell:
		style.set_border_width_all(4)
		style.border_color = Color("#F29A62")
	tile.add_theme_stylebox_override("normal", style)
	tile.add_theme_stylebox_override("hover", style)
	tile.add_theme_stylebox_override("pressed", style)
	tile.add_theme_stylebox_override("focus", style)

func _refresh_board() -> void:
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			_refresh_tile(Vector2i(x, y))

func _update_score() -> void:
	score_label.text = "Угощения: %d / %d" % [score, SHOP_GOAL]


func _return_to_map() -> void:
	GameState.return_to_map()
