class_name MenuController extends Node

var _project_data: ProjectData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ProjectManager.project_loaded.connect(_on_project_loaded)

func _on_project_loaded() -> void:
	_on_project_reset()
	_project_data = ProjectManager.current_project

func _on_project_reset() -> void:
	push_warning("_on_project_reset must be implemented by child class.")

func get_project_data() -> ProjectData:
	return _project_data