extends Node

enum StoryStep { SHOP, GATHER, PARTY, FINISHED }
var story_step = StoryStep.SHOP
var high_scores = {"match3": 0, "catio": 0}

const MINIGAMES = {
	"catio": "res://scenes/minigames/catio/CatIO.tscn"
}

func start_minigame(game_key: String):
	get_tree().change_scene_to_file(MINIGAMES[game_key])

func save_game():
	var data = {"story_step": story_step, "high_scores": high_scores}
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_line(JSON.stringify(data))
