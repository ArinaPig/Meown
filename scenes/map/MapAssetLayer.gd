extends Control
## Loads a modular pixel-art map from res://assets/map/map_manifest.json.
## The built-in WorldMap drawing remains visible unless the manifest is complete
## and its canvas matches the active map layout.

const MANIFEST_PATH := "res://assets/map/map_manifest.json"
const REQUIRED_LAYER_NAMES := ["map_background", "main_path", "shop_building", "home_building", "party_picnic"]

var _asset_pack_active: bool = false
var _loaded_layers: int = 0
var _layout_is_landscape: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_is_landscape = _is_landscape_layout()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_load_asset_pack()

func is_asset_pack_active() -> bool:
	return _asset_pack_active

func get_loaded_layer_count() -> int:
	return _loaded_layers

func _is_landscape_layout() -> bool:
	var viewport_size := get_viewport_rect().size
	return viewport_size.x > viewport_size.y and viewport_size.x >= 700.0

func _on_viewport_size_changed() -> void:
	var next_is_landscape := _is_landscape_layout()
	if next_is_landscape == _layout_is_landscape:
		return

	_layout_is_landscape = next_is_landscape
	_clear_loaded_layers()
	_load_asset_pack()

func _clear_loaded_layers() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_asset_pack_active = false
	_loaded_layers = 0

func _load_asset_pack() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return

	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_warning("Map assets: could not open map manifest.")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Map assets: manifest must contain a JSON object.")
		return

	var manifest: Dictionary = parsed
	var canvas_value: Variant = manifest.get("canvas", [])
	if typeof(canvas_value) != TYPE_ARRAY or canvas_value.size() < 2:
		push_warning("Map assets: manifest must declare its canvas as [width, height].")
		return

	var expected_canvas := Vector2(1280.0, 800.0) if _layout_is_landscape else Vector2(480.0, 800.0)
	var manifest_canvas := Vector2(float(canvas_value[0]), float(canvas_value[1]))
	if manifest_canvas != expected_canvas:
		# Portrait and landscape maps use different compositions. Never stretch
		# a 480x800 art pack across the 1280x800 tablet layout (or vice versa).
		return

	var layers_value: Variant = manifest.get("layers", [])
	if typeof(layers_value) != TYPE_ARRAY:
		push_warning("Map assets: manifest 'layers' must be an array.")
		return

	var pending_layers: Array[Dictionary] = []
	var missing_required: Array[String] = []
	var declared_required_names: Array[String] = []

	for layer_value in layers_value:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue

		var layer: Dictionary = layer_value
		var layer_name := str(layer.get("name", ""))
		var texture_path := str(layer.get("texture", ""))
		var is_required := bool(layer.get("required", true))
		if is_required and not layer_name.is_empty() and not declared_required_names.has(layer_name):
			declared_required_names.append(layer_name)

		if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
			if is_required:
				missing_required.append(texture_path if not texture_path.is_empty() else "(empty texture path)")
			continue

		var texture_resource: Resource = load(texture_path)
		if not texture_resource is Texture2D:
			if is_required:
				missing_required.append(texture_path + " (not a Texture2D)")
			continue

		pending_layers.append(layer)
		_loaded_layers += 1

	for required_name in REQUIRED_LAYER_NAMES:
		if not declared_required_names.has(required_name):
			missing_required.append("required layer not declared: " + required_name)

	var manifest_complete := bool(manifest.get("complete", false))
	if not manifest_complete or not missing_required.is_empty() or pending_layers.is_empty():
		_loaded_layers = 0
		if not missing_required.is_empty():
			push_warning("Map assets are incomplete. Keeping the built-in map. Missing: " + str(missing_required))
		return

	for layer in pending_layers:
		_add_texture_layer(layer)

	_asset_pack_active = true
	print("Map assets loaded: ", _loaded_layers, " layers.")

func _add_texture_layer(layer: Dictionary) -> void:
	var texture_path := str(layer.get("texture", ""))
	var texture := load(texture_path) as Texture2D
	if texture == null:
		return

	var sprite := TextureRect.new()
	sprite.name = str(layer.get("name", texture_path.get_file().get_basename()))
	sprite.texture = texture
	sprite.position = _read_vector(layer.get("position", [0, 0]), Vector2.ZERO)
	sprite.size = _read_vector(layer.get("size", [texture.get_width(), texture.get_height()]), Vector2(texture.get_width(), texture.get_height()))
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.z_index = int(layer.get("z_index", 0))
	add_child(sprite)

func _read_vector(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) == TYPE_ARRAY and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback
