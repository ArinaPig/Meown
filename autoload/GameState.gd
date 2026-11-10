extends Node

enum StoryStep { SHOP, GATHER, PARTY, FINISHED }

const SAVE_PATH := "user://meown_save.json"
const MINIGAMES := {
	"shop": "res://scenes/minigames/match3/Match3.tscn",
	"catio": "res://scenes/minigames/catio/CatIO.tscn"
}

# The search scene is made by the other team member. Set its path here
# when that scene is added to the project.
var search_scene_path := ""

var story_step: int = StoryStep.SHOP
var high_scores: Dictionary = {"match3": 0, "catio": 0}

func _ready() -> void:
	load_game()

func is_unlocked(game_key: String) -> bool:
	match game_key:
		"shop":
			return true
		"search":
			return story_step >= StoryStep.GATHER
		"catio":
			return story_step >= StoryStep.PARTY
	return false

func start_minigame(game_key: String) -> bool:
	if not is_unlocked(game_key):
		return false
	var scene_path := str(MINIGAMES.get(game_key, ""))
	if game_key == "search":
		scene_path = search_scene_path
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return false
	get_tree().change_scene_to_file(scene_path)
	return true

func complete_shop() -> void:
	if story_step < StoryStep.GATHER:
		story_step = StoryStep.GATHER
		save_game()

func complete_search() -> void:
	if story_step < StoryStep.PARTY:
		story_step = StoryStep.PARTY
		save_game()

func complete_party() -> void:
	if story_step < StoryStep.FINISHED:
		story_step = StoryStep.FINISHED
		save_game()

func return_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map/WorldMap.tscn")

func save_game() -> void:
	var data := {
		"story_step": story_step,
		"high_scores": high_scores
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify(data))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	story_step = clampi(int(parsed.get("story_step", StoryStep.SHOP)), StoryStep.SHOP, StoryStep.FINISHED)
	var saved_scores: Variant = parsed.get("high_scores", {})
	if saved_scores is Dictionary:
		high_scores = saved_scores
