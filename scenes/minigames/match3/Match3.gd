extends Control

# Match-3 для Meown — визуальная тема Kitten Cafe.
# Фишки: PNG-спрайты из res://assets/minigames/match3/.
# Управление: выберите две соседние фишки.

const BOARD_SIZE := 7
const TASK_AMOUNT := 12
const STARTING_MOVES := 20
const TILE_NAMES: Array[String] = ["рыбок", "бутылочек молока", "пирожных", "пончиков", "кусочков сыра", "курочек", "клубочков"]
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
var moves_left := STARTING_MOVES
var target_kind := 2
var target_collected := 0
var game_over := false
var result_overlay: Control
var busy := false
var pointer_start_cell := Vector2i(-1, -1)
var pointer_active := false

var score_label: Label
var task_label: Label
var moves_label: Label
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

	var task_panel := PanelContainer.new()
	var task_style := StyleBoxFlat.new()
	task_style.bg_color = Color("#FFF7E8")
	task_style.border_color = CAFE_BROWN
	task_style.set_border_width_all(2)
	task_style.set_corner_radius_all(12)
	task_panel.add_theme_stylebox_override("panel", task_style)
	layout.add_child(task_panel)

	var task_layout := VBoxContainer.new()
	task_layout.add_theme_constant_override("separation", 3)
	task_panel.add_child(task_layout)

	task_label = Label.new()
	task_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	task_label.add_theme_font_size_override("font_size", 17)
	task_label.add_theme_color_override("font_color", CAFE_BROWN)
	task_layout.add_child(task_label)

	moves_label = Label.new()
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_label.add_theme_font_size_override("font_size", 15)
	moves_label.add_theme_color_override("font_color", CAFE_MUTED)
	task_layout.add_child(moves_label)

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
	moves_left = STARTING_MOVES
	target_kind = randi() % TILE_TEXTURES.size()
	target_collected = 0
	game_over = false
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
	if not _has_possible_move():
		_shuffle_board()
	_update_score()
	_update_task_display()
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
	if busy or game_over:
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

	moves_left -= 1
	_update_task_display()
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
		for cell in matches:
			if int(board[cell.y][cell.x]) == target_kind:
				target_collected += 1
		_update_task_display()
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

	_update_score()
	_update_task_display()
	if target_collected >= TASK_AMOUNT:
		_finish_game(true)
		return
	if moves_left <= 0:
		_finish_game(false)
		return
	if not _has_possible_move():
		_shuffle_board()

	hint_label.text = "Отлично! Продолжай выполнять заказ"
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
	# Сначала пробуем сохранить набор фишек, меняя только их расположение.
	var values: Array[int] = []
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			values.append(int(board[y][x]))
	values.shuffle()

	var found_playable_layout := false
	for attempt in range(100):
		var index := 0
		for y in range(BOARD_SIZE):
			for x in range(BOARD_SIZE):
				board[y][x] = values[index]
				index += 1
		if _find_matches().is_empty() and _has_possible_move():
			found_playable_layout = true
			break
		values.shuffle()

	# Крайний случай: создаём проверенную раскладку, в которой точно есть ход.
	if not found_playable_layout:
		_create_guaranteed_playable_board()

	_refresh_board()
	hint_label.text = "Фишки перемешаны — появились новые ходы!"

func _create_guaranteed_playable_board() -> void:
	# Базовый узор не содержит готовых троек по горизонтали и вертикали.
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			board[y][x] = (x + y * 2) % TILE_TEXTURES.size()

	# Подготавливаем ход: обмен (0, 1) с (1, 1) соберёт три фишки типа 0.
	board[0][0] = 0
	board[0][1] = 1
	board[0][2] = 0
	board[1][1] = 0
	board[2][1] = 0
	board[3][1] = 5

	# Защита от будущих изменений размера поля или палитры.
	if not _find_matches().is_empty() or not _has_possible_move():
		for y in range(BOARD_SIZE):
			for x in range(BOARD_SIZE):
				board[y][x] = (x + y) % TILE_TEXTURES.size()
		board[0][0] = 0
		board[0][1] = 1
		board[0][2] = 0
		board[1][1] = 0
		board[2][1] = 0
		board[3][1] = 4

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
	var best_score: int = int(GameState.high_scores.get("match3", 0))
	if score > best_score:
		GameState.high_scores["match3"] = score
		GameState.save_game()
		best_score = score
	score_label.text = "Угощения: %d / %d   Рекорд: %d" % [score, SHOP_GOAL, best_score]


func _update_task_display() -> void:
	if task_label == null or moves_label == null:
		return
	task_label.text = "Заказ: собери %d %s — %d / %d" % [TASK_AMOUNT, TILE_NAMES[target_kind], target_collected, TASK_AMOUNT]
	moves_label.text = "Осталось ходов: %d" % moves_left

func _finish_game(won: bool) -> void:
	if game_over:
		return
	game_over = true
	busy = true
	if won and GameState.story_step == GameState.StoryStep.SHOP:
		GameState.complete_shop()

	result_overlay = Control.new()
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(result_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.22, 0.12, 0.10, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(330, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = CAFE_PANEL
	panel_style.border_color = CAFE_BROWN
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(18)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var result_title := Label.new()
	result_title.text = "Заказ выполнен!" if won else "Не хватило ходов..."
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 24)
	result_title.add_theme_color_override("font_color", CAFE_BROWN)
	content.add_child(result_title)

	var result_text := Label.new()
	if won:
		result_text.text = "Ура! Котокафе получит свои вкусности!\nСобрано: %d из %d" % [target_collected, TASK_AMOUNT]
	else:
		result_text.text = "Заказ пока не готов.\nСобрано: %d из %d" % [target_collected, TASK_AMOUNT]
	result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_text.add_theme_font_size_override("font_size", 16)
	result_text.add_theme_color_override("font_color", CAFE_MUTED)
	content.add_child(result_text)

	var retry_button := Button.new()
	retry_button.text = "Попробовать ещё"
	retry_button.custom_minimum_size = Vector2(0, 48)
	retry_button.pressed.connect(_restart_from_result)
	content.add_child(retry_button)

	var map_button := Button.new()
	map_button.text = "На карту"
	map_button.custom_minimum_size = Vector2(0, 44)
	map_button.pressed.connect(_return_to_map)
	content.add_child(map_button)

func _restart_from_result() -> void:
	if is_instance_valid(result_overlay):
		result_overlay.queue_free()
	result_overlay = null
	busy = false
	_new_game()

func _return_to_map() -> void:
	GameState.return_to_map()
