class_name TaggingState extends RefCounted

var controller: TaggingViewController

func _init(ctrl: TaggingViewController) -> void:
	controller = ctrl

func enter() -> void:
	pass

func exit() -> void:
	pass

func on_selection_changed() -> void:
	pass

func apply_changes() -> void:
	pass

func discard_changes() -> void:
	pass

func set_image(_path: String) -> void:
	pass

func on_next_pressed() -> void:
	pass

func on_previous_pressed() -> void:
	pass