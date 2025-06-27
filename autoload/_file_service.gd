extends Node

signal file_removed(path: String)
signal file_created(path: String)

func _ready() -> void:
	pass

## Copy existing file to from A to B. Returns the new path of the new file. If copying failed, returns an empty string.
func copy_file(path: String, new_path: String, safe: bool = true) -> String:
	if !FileAccess.file_exists(path):
		push_error("File does not exist: ", path)
		return ""
	
	if FileAccess.file_exists(new_path):
		if !safe:
			push_error("File already exists: ", new_path)
			return ""
		new_path = get_unique_file_path(new_path.get_base_dir(), new_path.get_file())
	var err := DirAccess.copy_absolute(path, new_path)
	if err != OK:
		push_error("Failed to copy original file: ", path)
		return ""
	
	file_created.emit(new_path)
	return new_path
	
## Remove existing file. Requires absolute path.
func remove_file(path: String) -> void:
	if !FileAccess.file_exists(path):
		return
	
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		push_error("Failed to remove file: ", path)
	
	file_removed.emit(path)

## Move existing file from A to B. Requires absolute paths
func move_file(old_path: String, new_path: String, safe: bool = true) -> void:
	if old_path == new_path:
		return

	var path := copy_file(old_path, new_path, safe)
	if path.is_empty():
		return
	remove_file(old_path)

## generates a unique file path based on a file's original name.
func get_unique_file_path(base_path: String, filename: String) -> String:
	var file_exists := true
	var counter := 0
	
	var dot_ext := "." + filename.get_extension() 
	var file_path := ""
	var file_name := filename.get_basename()
	var new_name := file_name

	while file_exists:
		file_path = base_path.path_join(new_name + dot_ext)
		file_exists = FileAccess.file_exists(file_path)
		if file_exists:
			counter += 1
			new_name = "%s_%d" % [file_name, counter]
	
	return file_path