class_name MenuController extends Node

var _project_data: DatabaseAdapter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ProjectManager.project_loaded.connect(_on_project_loaded)

func _on_project_loaded() -> void:
	_on_project_reset()
	_project_data = ProjectManager.database_adapter

func _on_project_reset() -> void:
	pass

func get_project_data() -> DatabaseAdapter:
	return _project_data