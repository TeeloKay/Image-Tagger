class_name DirectoryController extends MenuController

@export var directory_view: DirectoryView
@export_dir var _current_directory: String

signal path_selected(path: String)

func _ready() -> void:
	super._ready()

	directory_view.folder_selected.connect(_on_folder_selected)
	directory_view.data_dropped.connect(_on_data_dropped)

func _on_project_loaded() -> void:
	super._on_project_loaded()
	_current_directory = _project_data.project_path
	_update_view()
	path_selected.emit(_current_directory)

func _on_folder_selected(path: String) -> void:
	_current_directory = path
	path_selected.emit(_current_directory)

func _on_data_dropped(from: String, to: String) -> void:
	print(from, " -> ", to)

func _on_delete_request(path: String) -> void:
	var dir := DirAccess.open(path)
	if !dir:
		push_error("Error opening directory at path: ", path)
		return
	
	print("deleting directory and all its contents (not)")

func _update_view() -> void:
	directory_view.build_directory_tree(_current_directory)
	directory_view.clear_filter()
