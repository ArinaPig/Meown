
extends Area2D

signal item_found

var found: bool = false


func _input_event(_viewport, event, _shape_idx):
	if found:
		return

	var pressed := false
	if event is InputEventMouseButton:
		pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	elif event is InputEventScreenTouch:
		pressed = event.pressed

	if pressed:
		found = true
		item_found.emit()
		print("Предмет найден!")
		hide()
		input_pickable = false
