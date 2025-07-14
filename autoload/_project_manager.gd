extends Node

const REGISTRY_PATH := "user://registry.tres"

@export var registry: ProjectRegistry
@export var current_project: ProjectData

var _project_io: ProjectIO

@onready var search_engine: SearchEngine = $SearchEngine
@onready var image_indexer: ImageIndexer = $ImageIndexer
@onready var registrar: ImageRegistrar = $ImageRegistrar
@onready var file_hasher: ImageHasher = $ImageHasher
@onready var tagging_queue: TaggingQueue = $TaggingQueue
@onready var databse_bridge: DatabaseBridge = $DatabaseBridge

signal project_loaded

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_project_io = ProjectIO.new()
	image_indexer = ImageIndexer.new()
	
	project_loaded.connect(ThumbnailManager.clear_queue)

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
	_project_io.save_project(current_project)
	
func open_project(project_path: String) -> void:
	print("open project")
	registry.register_project(project_path)
	save_registry()
	
	current_project = _project_io.load_project(project_path)
	var db_path := current_project.project_path.path_join(".artmeta/project.db")
	databse_bridge.open_database(db_path)

	tagging_queue.project = current_project
	search_engine.project = current_project
	image_indexer.project = current_project
	registrar.project = current_project
	ThumbnailManager.clear()

	project_loaded.emit()

func get_valid_projects() -> Array[String]:
	if !registry:
		return []
	return registry.get_valid_projects()

func search_files(query: SearchQuery) -> void:
	search_engine.start_search(query)

func to_relative_path(abs_path: String) -> String:
	if current_project:
		return current_project.to_relative_path(abs_path)
	return abs_path

func to_abolute_path(rel_path: String) -> String:
	if current_project:
		return current_project.to_abolute_path(rel_path)
	return rel_path

func register_image(path: String) -> void:
	registrar.register_image(path)
