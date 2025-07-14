class_name DirectoryWatcherBridge extends Node

@export_global_dir var watched_directory: String = ""
@export var watched_extensions: Array[String] = ["png", "jpg", "gif"]

var _watcher: Node

signal file_created(path: String)
signal file_changed(path: String)
signal file_deleted(path: String)
signal file_renamed(old_path: String, new_path: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var watcher_script := load("res://scripts/filesystem/DirectoryWatcher.cs")
	_watcher = watcher_script.new()

	add_child(_watcher, INTERNAL_MODE_BACK)

	_watcher.connect("FileCreated", _on_file_created)
	_watcher.connect("FileChanged", _on_file_changed)
	_watcher.connect("FileDeleted", _on_file_deleted)
	_watcher.connect("FileRenamed", _on_file_renamed)

	if !watched_directory.is_empty() && DirAccess.dir_exists_absolute(watched_directory):
		start_watching(watched_directory)

func start_watching(path: String) -> void:
	watched_directory = ProjectSettings.globalize_path(path)
	if _watcher:
		_watcher.StartWatching(watched_directory)

func stop_watching() -> void:
	if _watcher:
		_watcher.StopWatching()

func _on_file_created(file: String) -> void:
	print("file created: ", file)
	file_created.emit(file)

func _on_file_changed(file: String) -> void:
	print("file changed: ", file)
	file_changed.emit(file)

func _on_file_deleted(file: String) -> void:
	print("file deleted: ", file)
	file_deleted.emit(file)

func _on_file_renamed(old_path: String, new_path: String) -> void:
	print("file renamed: ", old_path, " -> ", new_path)
	file_renamed.emit(old_path, new_path)

func _exit_tree() -> void:
	stop_watching()
