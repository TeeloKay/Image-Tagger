class_name MenuController extends Node

var _database: DatabaseAdapter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ProjectContext.project_loaded.connect(_on_project_loaded)
	_database = ProjectContext.database_adapter

func _on_project_loaded() -> void:
	_on_project_reset()

func _on_project_reset() -> void:
	pass

func get_project_data() -> DatabaseAdapter:
	return _database
