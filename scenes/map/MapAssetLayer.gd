extends Control
## Loads a modular pixel-art map from a layout-specific manifest.
## The built-in WorldMap drawing remains visible unless the entire pack is valid.

const PORTRAIT_MANIFEST_PATH := "res://assets/map/map_manifest.json"
const LANDSCAPE_MANIFEST_PATH := "res://assets/map/map_manifest.landscape.json"
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
	var manifest_path := LANDSCAPE_MANIFEST_PATH if _layout_is_landscape else PORTRAIT_MANIFEST_PATH
	if not FileAccess.file_exists(manifest_path):
		return

	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		push_warning("Map assets: could not open map manifest. Keeping the built-in map.")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Map assets: manifest must contain a JSON object. Keeping the built-in map.")
		return

	var manifest: Dictionary = parsed
	if not bool(manifest.get("complete", false)):
		return

	var canvas_value: Variant = manifest.get("canvas", [])
	if not _is_vector_pair(canvas_value):
		push_warning("Map assets: manifest canvas must be [width, height]. Keeping the built-in map.")
		return

	var expected_canvas := Vector2(1280.0, 800.0) if _layout_is_landscape else Vector2(480.0, 800.0)
	var manifest_canvas := Vector2(float(canvas_value[0]), float(canvas_value[1]))
	if manifest_canvas != expected_canvas:
		# Never stretch portrait artwork across the landscape tablet layout, or vice versa.
		return

	var layers_value: Variant = manifest.get("layers", [])
	if typeof(layers_value) != TYPE_ARRAY:
		push_warning("Map assets: manifest 'layers' must be an array. Keeping the built-in map.")
		return

	# Validate the complete manifest before creating any visible nodes. This avoids
	# displaying a partially loaded art pack if one required resource is invalid.
	var pending_layers: Array[Dictionary] = []
	var seen_names: Dictionary = {}
	var declared_required_names: Dictionary = {}
	var errors: Array[String] = []

	for layer_value in layers_value:
		if typeof(layer_value) != TYPE_DICTIONARY:
			errors.append("layer entry is not an object")
			continue

		var layer: Dictionary = layer_value
		var layer_name := str(layer.get("name", "")).strip_edges()
		var texture_path := str(layer.get("texture", "")).strip_edges()
		var is_required := bool(layer.get("required", true))

		if layer_name.is_empty():
			errors.append("layer has no name")
		elif seen_names.has(layer_name):
			errors.append("duplicate layer name: " + layer_name)
		else:
			seen_names[layer_name] = true

		if is_required and not layer_name.is_empty():
			declared_required_names[layer_name] = true

		var position_value: Variant = layer.get("position", [])
		var size_value: Variant = layer.get("size", [])
		if not _is_vector_pair(position_value) or not _is_vector_pair(size_value):
			errors.append("layer '" + layer_name + "' must declare position and size as two-value arrays")
			continue

		var layer_position := Vector2(float(position_value[0]), float(position_value[1]))
		var layer_size := Vector2(float(size_value[0]), float(size_value[1]))
		if not is_finite(layer_position.x) or not is_finite(layer_position.y) or not is_finite(layer_size.x) or not is_finite(layer_size.y):
			errors.append("layer '" + layer_name + "' has non-finite bounds")
			continue
		if layer_size.x <= 0.0 or layer_size.y <= 0.0 or layer_position.x < 0.0 or layer_position.y < 0.0 or layer_position.x + layer_size.x > expected_canvas.x or layer_position.y + layer_size.y > expected_canvas.y:
			errors.append("layer '" + layer_name + "' has invalid bounds outside the canvas")
			continue

		if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
			if is_required:
				errors.append("missing required texture for '" + layer_name + "': " + texture_path)
			continue

		var texture_resource: Resource = load(texture_path)
		if not texture_resource is Texture2D:
			if is_required:
				errors.append("required resource is not a Texture2D: " + texture_path)
			continue

		pending_layers.append(layer)

	for required_name in REQUIRED_LAYER_NAMES:
		if not declared_required_names.has(required_name):
			errors.append("required layer is missing or not marked required: " + required_name)

	if not errors.is_empty() or pending_layers.is_empty():
		push_warning("Map asset pack rejected. Keeping the built-in map. Problems: " + str(errors))
		return

	for layer in pending_layers:
		_add_texture_layer(layer)

	_loaded_layers = pending_layers.size()
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

func _is_vector_pair(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY and value.size() >= 2

func _read_vector(value: Variant, fallback: Vector2) -> Vector2:
	if _is_vector_pair(value):
		return Vector2(float(value[0]), float(value[1]))
	return fallback
