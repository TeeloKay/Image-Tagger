@tool class_name TextInputDialog extends ConfirmationDialog

@onready var _input: LineEdit = %LineEdit

@export_global_dir var parent_folder: String = ""
var is_valid: bool:
	set = set_is_valid

signal input_changed(path_name: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_input.text_changed.connect(_on_input_changed)
	_input.text_submitted.connect(func(_txt: String) -> void: get_ok_button().grab_focus())
	_input.grab_focus()
	_input.select_all()

func _on_input_changed(text: String) -> void:
	input_changed.emit(text.strip_edges().strip_escapes())
	
func get_input_text() -> String:
	return _input.text.strip_edges().strip_escapes()

func set_is_valid(valid: bool) -> void:
	is_valid = valid
	get_ok_button().disabled = !is_valid
