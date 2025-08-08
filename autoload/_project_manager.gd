extends Node

const REGISTRY_PATH := "user://registry.tres"

@export var registry: ProjectRegistry
@export var project_path: String
@export var database_adapter: DatabaseAdapter
@export var search_engine: SearchEngine

@export var image_import_service: ImageImportService
@export var tagging_queue: TaggingQueue
var thumbnail_cache: ThumbnailCache

signal project_loaded

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	thumbnail_cache = ThumbnailCache.new()
	# _project_io = ProjectIO.new()
	
	project_loaded.connect(ThumbnailManager.clear_queue)
	database_adapter.database_opened.connect(func(_val: String) -> void: ThumbnailManager.clear_queue())

	tagging_queue.project = database_adapter
	search_engine.project = database_adapter

	load_project_registry()

func load_project_registry() -> void:
	if FileAccess.file_exists(REGISTRY_PATH):
		registry = ResourceLoader.load(REGISTRY_PATH, "ProjectRegistry")
		if registry:
			return
	registry = ProjectRegistry.new()
	save_registry()

func save_registry() -> void:
	ResourceSaver.save(registry, REGISTRY_PATH)

func save_current_project() -> void:
	# _project_io.save_project(current_project)
	pass
	
func open_project(project_path: String) -> void:
	FileSystemWatcher.stop_watching()
	
	registry.register_project(project_path)
	save_registry()
	
	self.project_path = project_path
	database_adapter.set_database_path(project_path.path_join(".artmeta").path_join("images.db"))
	database_adapter.open_database()

	FileSystemWatcher.start_watching(project_path)

	project_loaded.emit()

func get_valid_projects() -> Array[String]:
	if !registry:
		return []
	return registry.get_valid_projects()

func search_files(query: SearchQuery) -> void:
	search_engine.start_search(query)

func to_relative_path(abs_path: String) -> String:
	if abs_path.begins_with(project_path):
		return abs_path.replace(project_path + "/", "")
	return abs_path

func to_abolute_path(rel_path: String) -> String:
	if rel_path.begins_with(project_path + "/"):
		return rel_path
	return project_path.path_join(rel_path)
