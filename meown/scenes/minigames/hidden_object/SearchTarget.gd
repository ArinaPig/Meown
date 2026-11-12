
extends Area2D

signal item_found

var found: bool = false


func _input_event(_viewport, event, _shape_idx):
	if found:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			found = true
			item_found.emit()
			print("Предмет найден!")
			hide()
			set_process_input(false)
