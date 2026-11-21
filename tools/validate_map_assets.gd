extends SceneTree
## Run with:
## godot --headless --path . --script res://tools/validate_map_assets.gd
##
## This checks active map manifests without changing the project. Missing active
## manifests are expected while the artwork is still being prepared.

const MAP_PACKS := [
	{
		"path": "res://assets/map/map_manifest.json",
		"canvas": Vector2i(480, 800),
		"label": "portrait"
	},
	{
		"path": "res://assets/map/map_manifest.landscape.json",
		"canvas": Vector2i(1280, 800),
		"label": "landscape tablet"
	}
]

const REQUIRED_LAYERS := [
	"map_background",
	"main_path",
	"shop_building",
	"home_building",
	"party_picnic"
]

func _initialize() -> void:
	call_deferred("_validate_all")

func _validate_all() -> void:
	var active_count := 0
	var has_errors := false

	for pack in MAP_PACKS:
		var manifest_path: String = pack["path"]
		if not FileAccess.file_exists(manifest_path):
			print("SKIP ", pack["label"], ": active manifest not created yet.")
			continue

		active_count += 1
		if not _validate_manifest(manifest_path, pack["canvas"], pack["label"]):
			has_errors = true

	if active_count == 0:
		print("No active map packs yet. The built-in fallback map should remain visible.")
	elif has_errors:
		push_error("Map asset validation failed. Do not activate this pack in-game yet.")
	else:
		print("All active map packs passed validation.")

	quit(1 if has_errors else 0)

func _validate_manifest(path: String, expected_canvas: Vector2i, label: String) -> bool:
	var valid := true
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error(label + ": cannot open " + path)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error(label + ": manifest must be a JSON object.")
		return false

	var manifest: Dictionary = parsed
	if not bool(manifest.get("complete", false)):
		push_error(label + ": complete must be true for an active manifest.")
		valid = false

	var canvas_value: Variant = manifest.get("canvas", [])
	if typeof(canvas_value) != TYPE_ARRAY or canvas_value.size() < 2:
		push_error(label + ": canvas must be [width, height].")
		return false

	var actual_canvas := Vector2i(int(canvas_value[0]), int(canvas_value[1]))
	if actual_canvas != expected_canvas:
		push_error(label + ": expected canvas " + str(expected_canvas) + ", got " + str(actual_canvas) + ".")
		valid = false

	var layers_value: Variant = manifest.get("layers", [])
	if typeof(layers_value) != TYPE_ARRAY:
		push_error(label + ": layers must be an array.")
		return false

	var seen_names: Dictionary = {}
	var found_required: Dictionary = {}
	for layer_value in layers_value:
		if typeof(layer_value) != TYPE_DICTIONARY:
			push_error(label + ": every layer entry must be an object.")
			valid = false
			continue

		var layer: Dictionary = layer_value
		var layer_name := str(layer.get("name", "")).strip_edges()
		var texture_path := str(layer.get("texture", "")).strip_edges()
		var is_required := bool(layer.get("required", true))

		if layer_name.is_empty():
			push_error(label + ": a layer has no name.")
			valid = false
		elif seen_names.has(layer_name):
			push_error(label + ": duplicate layer name '" + layer_name + "'.")
			valid = false
		else:
			seen_names[layer_name] = true

		if is_required and not layer_name.is_empty():
			found_required[layer_name] = true

		if texture_path.is_empty():
			if is_required:
				push_error(label + ": required layer '" + layer_name + "' has no texture path.")
				valid = false
			continue

		if not FileAccess.file_exists(texture_path):
			if is_required:
				push_error(label + ": missing required texture " + texture_path)
				valid = false
			else:
				print("WARN ", label, ": optional texture missing: ", texture_path)
			continue

		var texture: Resource = ResourceLoader.load(texture_path)
		if not texture is Texture2D:
			if is_required:
				push_error(label + ": required resource is not a Texture2D: " + texture_path)
				valid = false
			else:
				print("WARN ", label, ": optional resource is not a Texture2D: ", texture_path)

		var position_value: Variant = layer.get("position", [0, 0])
		var size_value: Variant = layer.get("size", [])
		if not _is_vector_pair(position_value) or not _is_vector_pair(size_value):
			push_error(label + ": layer '" + layer_name + "' must have two-value position and size arrays.")
			valid = false
			continue

		var position := Vector2(float(position_value[0]), float(position_value[1]))
		var size := Vector2(float(size_value[0]), float(size_value[1]))
		if size.x <= 0.0 or size.y <= 0.0:
			push_error(label + ": layer '" + layer_name + "' has a non-positive size.")
			valid = false
		elif position.x < 0.0 or position.y < 0.0 or position.x + size.x > expected_canvas.x or position.y + size.y > expected_canvas.y:
			push_error(label + ": layer '" + layer_name + "' extends outside the canvas.")
			valid = false

	for required_name in REQUIRED_LAYERS:
		if not found_required.has(required_name):
			push_error(label + ": required layer is missing or not marked required: " + required_name)
			valid = false

	if valid:
		print("PASS ", label, ": ", path)
	return valid

func _is_vector_pair(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY and value.size() >= 2
