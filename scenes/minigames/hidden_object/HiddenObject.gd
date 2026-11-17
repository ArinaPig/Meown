
extends Node2D

var found_count: int = 0
const TOTAL_ITEMS: int = 4

@onready var counter_label: Label = $CounterPanel/Label
@onready var bow_target: Area2D = $Targets/BowTarget


func _ready():
	bow_target.item_found.connect(_on_item_found)


func _on_item_found():
	print("Главная сцена получила сигнал!")
	found_count += 1
	counter_label.text = "Найдено: %d / %d" % [found_count, TOTAL_ITEMS]
