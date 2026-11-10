extends Control
## Loads the modular pixel-art map from res://assets/map/map_manifest.json.
## The existing WorldMap drawing remains visible until every required layer is available.

const MANIFEST_PATH := "res://assets/map/map_manifest.json"

var _asset_pack_active: bool = false
var _loaded_layers: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_asset_pack()

func is_asset_pack_active() -> bool:
	return _asset_pack_active

func get_loaded_layer_count() -> int:
	return _loaded_layers

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
	var layers_value: Variant = manifest.get("layers", [])
	if typeof(layers_value) != TYPE_ARRAY:
		push_warning("Map assets: manifest 'layers' must be an array.")
		return

	var pending_layers: Array[Dictionary] = []
	var missing_required: Array[String] = []

	for layer_value in layers_value:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue

		var layer: Dictionary = layer_value
		var texture_path := str(layer.get("texture", ""))
		var is_required := bool(layer.get("required", true))

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

	var manifest_complete := bool(manifest.get("complete", false))
	if not manifest_complete or not missing_required.is_empty() or pending_layers.is_empty():
		_loaded_layers = 0
		if not missing_required.is_empty():
			push_warning("Map assets are incomplete. Keeping the built-in map. Missing: " + ", ".join(missing_required))
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
	sprite.flip_h = bool(layer.get("flip_h", false))
	sprite.flip_v = bool(layer.get("flip_v", false))
	add_child(sprite)

func _read_vector(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) == TYPE_ARRAY and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback
