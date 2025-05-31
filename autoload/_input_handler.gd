extends Node

signal apply_changes

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save_project"):
		apply_changes.emit()
		ProjectManager.save_current_project()
