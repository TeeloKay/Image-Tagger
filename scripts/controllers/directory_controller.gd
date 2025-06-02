class_name DirectoryController extends Node

@export var directory_view: DirectoryView

var _project_data : ProjectData

signal path_selected(path: String)

func _ready() -> void:
	ProjectManager.project_loaded.connect(_on_project_loaded)

	directory_view.folder_selected.connect(_on_folder_selected)
	directory_view.data_dropped.connect(_on_data_dropped)

func _on_project_loaded() -> void:
	_project_data = ProjectManager.current_project
	var _current_directory = _project_data.project_path
	directory_view.build_directory_tree(_current_directory)

func _on_folder_selected(path: String) -> void:
	pass

func _on_data_dropped(from: String, to: String) -> void:
	print(from, " -> ", to)

func _on_delete_request(path: String) -> void:
	pass
