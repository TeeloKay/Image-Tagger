class_name FileSystemWatcher extends Node

@export_global_dir var watch_path: String = ""
@export var poll_interval := 2.0

signal file_created(path: String)
signal file_deleted(path: String)
signal file_modified(path: String)

var _previous_files: Dictionary = {}
var _timer: Timer

func _ready() -> void:
	if !DirAccess.dir_exists_absolute(watch_path):
		push_error("Directory does not exist: %s" % watch_path)
		return
	
	_previous_files = _scan_directory(watch_path)

	_timer = Timer.new()
	add_child(_timer, true, INTERNAL_MODE_FRONT)
	_timer.autostart = false
	_timer.one_shot = false
	_timer.timeout.connect(_check_for_changes)


func _check_for_changes() -> void:
	print("checking")
	var current_files := _scan_directory(watch_path)

	# Detect deleted files
	for file_path in _previous_files.keys():
		if !current_files.has(file_path):
			emit_signal("file_deleted", file_path)

	# Detect created or modified files
	for file_path in current_files.keys():
		if !_previous_files.has(file_path):
			emit_signal("file_created", file_path)
		elif _previous_files[file_path] != current_files[file_path]:
			emit_signal("file_modified", file_path)

	_previous_files = current_files
	
func _scan_directory(path: String) -> Dictionary:
	var files := {}
	var dir := DirAccess.open(path)
	if !dir:
		push_error("Failed to open directory: %s" % path)
		return files
	
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full_path = path.path_join(name)
		if dir.current_is_dir():
			files.merge(_scan_directory(full_path))
		else:
			var mod_time = FileAccess.get_modified_time(full_path)
			files[full_path] = mod_time
		name = dir.get_next()
	dir.list_dir_end()
	return files

