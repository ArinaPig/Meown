extends Control

# Первый прототип Match-3 для Meown (Godot 4.x).
# Управление: нажмите на фишку, затем на соседнюю по горизонтали или вертикали.

const BOARD_SIZE := 7
const TILE_SYMBOLS := ["🐟", "🧀", "🍓", "🥛", "🍪"]
const TILE_COLORS := [
	Color("#F5A65B"),
	Color("#F4D35E"),
	Color("#E98B9A"),
	Color("#A8DADC"),
	Color("#B8A1D9")
]

var board: Array = []
var tile_buttons: Array = []
var selected_cell := Vector2i(-1, -1)
var score := 0
var busy := false

var score_label: Label
var hint_label: Label
var grid: GridContainer

func _ready() -> void:
	_build_interface()
	_new_game()

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#FFF7EA")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 12)
	layout.add_theme_constant_override("margin_left", 14)
	layout.add_theme_constant_override("margin_right", 14)
	layout.add_theme_constant_override("margin_top", 24)
	layout.add_theme_constant_override("margin_bottom", 24)
	add_child(layout)

	var title := Label.new()
	title.text = "Лавка вкусностей"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#795548"))
	layout.add_child(title)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 21)
	score_label.add_theme_color_override("font_color", Color("#795548"))
	layout.add_child(score_label)

	hint_label = Label.new()
	hint_label.text = "Выбери две соседние фишки"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_color", Color("#8D6E63"))
	layout.add_child(hint_label)

	grid = GridContainer.new()
	grid.columns = BOARD_SIZE
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	layout.add_child(grid)

	for y in range(BOARD_SIZE):
		var row_buttons: Array = []
		for x in range(BOARD_SIZE):
			var tile := Button.new()
			tile.custom_minimum_size = Vector2(58, 58)
			tile.add_theme_font_size_override("font_size", 27)
			tile.pressed.connect(_on_tile_pressed.bind(Vector2i(x, y)))
			grid.add_child(tile)
			row_buttons.append(tile)
		tile_buttons.append(row_buttons)

	var restart := Button.new()
	restart.text = "Начать заново"
	restart.custom_minimum_size = Vector2(0, 48)
	restart.pressed.connect(_new_game)
	layout.add_child(restart)

func _new_game() -> void:
	score = 0
	selected_cell = Vector2i(-1, -1)
	board.clear()
	for y in range(BOARD_SIZE):
		var row: Array = []
		for x in range(BOARD_SIZE):
			row.append(randi() % TILE_SYMBOLS.size())
		board.append(row)
	# Убираем стартовые совпадения, чтобы игрок начинал с чистого поля.
	var initial_matches := _find_matches()
	while not initial_matches.is_empty():
		for cell in initial_matches:
			board[cell.y][cell.x] = randi() % TILE_SYMBOLS.size()
		initial_matches = _find_matches()
	_refresh_board()
	_update_score()
	hint_label.text = "Выбери две соседние фишки"

func _on_tile_pressed(cell: Vector2i) -> void:
	if busy:
		return
	if selected_cell.x < 0:
		selected_cell = cell
		_refresh_board()
		return
	if selected_cell == cell:
		selected_cell = Vector2i(-1, -1)
		_refresh_board()
		return
	if abs(selected_cell.x - cell.x) + abs(selected_cell.y - cell.y) != 1:
		selected_cell = cell
		_refresh_board()
		return

	var first := selected_cell
	selected_cell = Vector2i(-1, -1)
	_swap_cells(first, cell)
	var matches := _find_matches()
	if matches.is_empty():
		_swap_cells(first, cell)
		hint_label.text = "Совпадений нет — попробуй другой ход"
		_refresh_board()
		return

	busy = true
	_resolve_board()

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
			board[cell.y][cell.x] = -1
		_apply_gravity()
		_refill_board()
		matches = _find_matches()
	_update_score()
	_refresh_board()
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
				board[y][x] = randi() % TILE_SYMBOLS.size()

func _refresh_board() -> void:
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var kind: int = board[y][x]
			var tile: Button = tile_buttons[y][x]
			tile.text = TILE_SYMBOLS[kind]
			var style := StyleBoxFlat.new()
			style.bg_color = TILE_COLORS[kind]
			style.corner_radius_top_left = 10
			style.corner_radius_top_right = 10
			style.corner_radius_bottom_left = 10
			style.corner_radius_bottom_right = 10
			if selected_cell == Vector2i(x, y):
				style.border_width_left = 4
				style.border_width_top = 4
				style.border_width_right = 4
				style.border_width_bottom = 4
				style.border_color = Color("#795548")
			tile.add_theme_stylebox_override("normal", style)
			tile.add_theme_stylebox_override("hover", style)
			tile.add_theme_stylebox_override("pressed", style)

func _update_score() -> void:
	score_label.text = "Собрано вкусностей: %d" % score
