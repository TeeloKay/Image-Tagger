extends Node

signal apply_changes
signal update

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save_project"):
		apply_changes.emit()
	if event.is_action_pressed("update"):
		update.emit()
