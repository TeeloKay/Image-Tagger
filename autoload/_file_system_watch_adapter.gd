class_name FileSystemWatchAdapter extends Node

var _watcher: Node

signal watch_started(path: String)
signal watch_stopped

signal file_created(path: String)
signal file_changed(path: String)
signal file_deleted(path: String)
signal file_renamed(old_path: String, new_path: String)

signal folder_created(path: String)
signal folder_changed(path: String)
signal folder_deleted(path: String)
signal folder_renamed(old_path: String, new_path: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_watcher = preload("res://scripts/filesystem/ProjectFileSystemWatcher.cs").new()
	add_child(_watcher, INTERNAL_MODE_BACK)

	_watcher.WatchStarted.connect(_on_watch_started)
	_watcher.WatchStopped.connect(_on_watch_stopped)

	_watcher.FileCreated.connect(_on_file_created)
	_watcher.FileChanged.connect(_on_file_changed)
	_watcher.FileDeleted.connect(_on_file_deleted)
	_watcher.FileRenamed.connect(_on_file_renamed)

func start_watching(directory: String) -> void:
	_watcher.StartWatching(directory)

func stop_watching() -> void:
	print("ending directory watch")
	_watcher.StopWatching()

func set_filter(filter: PackedStringArray) -> void:
	_watcher.Filter = filter

func _on_watch_started(directory: String) -> void:
	print("started watching directory: ", directory)
	watch_started.emit()

func _on_watch_stopped() -> void:
	watch_stopped.emit()

func _on_file_created(path: String) -> void:
	if _is_file_valid_type(path):
		file_created.emit(path)
		return
	if _is_directory(path):
		folder_created.emit(path)

func _on_file_changed(path: String) -> void:
	if _is_file_valid_type(path):
		file_changed.emit(path)
		return
	if _is_directory(path):
		folder_changed.emit(path)

func _on_file_deleted(path: String) -> void:
	if _is_file_valid_type:
		file_deleted.emit(path)
		return
	if _is_directory(path):
		folder_deleted.emit(path)

func _on_file_renamed(old_path: String, new_path: String) -> void:
	if _is_file_valid_type(new_path):
		file_renamed.emit(old_path, new_path)
		return
	if _is_directory(new_path):
		folder_renamed.emit(old_path, new_path)

func _is_file_valid_type(path: String) -> bool:
	return path.get_extension() in ImageUtil.ACCEPTED_TYPES

func _is_directory(path: String) -> bool:
	return path.get_extension() == ""