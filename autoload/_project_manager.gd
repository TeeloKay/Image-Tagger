extends Node

const REGISTRY_PATH := "user://registry.tres"

var registry: ProjectRegistry
var current_project: ProjectData

var _project_io: ProjectIO
var search_engine: SearchEngine

var thumbnail_cache: ThumbnailCache
var image_hasher: ImageHasher
var image_indexer: ImageIndexer

signal project_loaded

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	thumbnail_cache = ThumbnailCache.new()
	_project_io = ProjectIO.new()
	search_engine = SearchEngine.new()
	image_hasher = ImageHasher.new()
	image_indexer = ImageIndexer.new()
	
	add_child(image_hasher, true, INTERNAL_MODE_BACK)

	project_loaded.connect(ThumbnailManager.clear_queue)

	load_project_registry()

func load_project_registry():
	if FileAccess.file_exists(REGISTRY_PATH):
		registry = ResourceLoader.load(REGISTRY_PATH, "ProjectRegistry")
		if registry:
			return
	registry = ProjectRegistry.new()
	save_registry()

func save_registry():
	ResourceSaver.save(registry, REGISTRY_PATH)

func save_current_project():
	_project_io.save_project(current_project)
	
func open_project(project_path: String) -> void:
	registry.register_project(project_path)
	save_registry()
	
	current_project = _project_io.load_project(project_path)
	# save_current_project()
	project_loaded.emit()

func get_valid_projects() -> Array[String]:
	if !registry:
		return []
	return registry.get_valid_projects()

func search_images(query: SearchQuery) -> Array:
	return search_engine.search_images(query)

func to_relative_path(abs_path: String) -> String:
	if current_project:
		return current_project.to_relative_path(abs_path)
	return abs_path

func to_abolute_path(rel_path: String) -> String:
	if current_project:
		return current_project.to_abolute_path(rel_path)
	return rel_path
