class_name CreateFolderDialog extends ConfirmationDialog

@onready var _line_edit: LineEdit = %LineEdit

@export_global_dir var parent_folder: String = ""

var _regex: RegEx

signal input_changed(path_name: String)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_line_edit.text_changed.connect(_on_input_changed)
	_regex = RegEx.new()
	_regex.compile("^\\.?[a-zA-Z0-9_~ ]*$")


func _on_input_changed(text: String) -> void:
	input_changed.emit(text)
	var search := _regex.search(text)
	if search == null:
		self.get_ok_button().disabled = true
		return
	var new_path := parent_folder.path_join(search.get_string())
	if !search.get_string().is_empty() || DirAccess.dir_exists_absolute(new_path):
		self.get_ok_button().disabled = false
