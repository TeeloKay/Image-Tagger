extends Node

const REGISTRY_PATH := "user://registry.tres"
const META_DIR_NAME := ".artmeta"
const PROJECT_FILE := "project.json"

var registry: ProjectRegistry
var current_project: ProjectData
var _current_meta_path: String = ""
var _current_project_file_path: String = ""

var _project_io: ProjectIO
var search_engine: SearchEngine

var thumbnail_cache: ThumbnailCache
var image_hasher: ImageHasher
var image_indexer: ImageIndexer
var file_system_watcher: Node

signal project_loaded

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_project_registry()
	
	thumbnail_cache = ThumbnailCache.new()
	
	_project_io = ProjectIO.new()
	search_engine = SearchEngine.new()
	image_hasher = ImageHasher.new()
	image_indexer = ImageIndexer.new()

	var watcher_script := load("res://scripts/filesystem/ProjectDirectoryWatcher.cs")
	file_system_watcher = watcher_script.new()

	add_child(file_system_watcher, true, INTERNAL_MODE_FRONT)
	add_child(image_hasher, true, INTERNAL_MODE_FRONT)

	file_system_watcher.FileCreated.connect(_on_file_created)
	file_system_watcher.FileRenamed.connect(_on_file_renamed)
	file_system_watcher.FileDeleted.connect(_on_file_deleted)
	file_system_watcher.FileChanged.connect(_on_file_changed)

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
	_current_meta_path = project_path.path_join(META_DIR_NAME)
	_current_project_file_path = _current_meta_path.path_join(PROJECT_FILE)
	
	if !DirAccess.dir_exists_absolute(_current_meta_path):
		DirAccess.make_dir_recursive_absolute(_current_meta_path)
	
	if FileAccess.file_exists(_current_project_file_path):
		current_project = _project_io.load_project(project_path)
	else:
		current_project = ProjectData.new()
		current_project.project_path = project_path
	
	image_hasher.initialize(current_project)
	registry.register_project(project_path)
	save_registry()
	
	image_indexer.index_project(current_project)
	save_current_project()
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

func _on_file_changed(path: String) -> void:
	print("file changed: ",path)