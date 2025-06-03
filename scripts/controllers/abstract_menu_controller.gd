class_name MenuController extends Node

var _project_data: ProjectData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ProjectManager.project_loaded.connect(_on_project_loaded)

func _on_project_loaded() -> void:
	_project_data = ProjectManager.current_project