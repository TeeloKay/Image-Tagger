extends Node

signal file_removed(path: String)
signal file_created(path: String)

func _ready() -> void:
	pass

## Copy existing file to from A to B.
func copy_file(path: String, new_path: String, safe: bool = true) -> Error:
	if !FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	
	if !new_path.get_file().is_valid_filename():
		return ERR_FILE_BAD_PATH

	if FileAccess.file_exists(new_path):
		if !safe:
			return ERR_FILE_ALREADY_IN_USE

	var err := DirAccess.copy_absolute(path, new_path)
	if err != OK:
		return ERR_FILE_CANT_WRITE
	
	file_created.emit(new_path)
	return OK
	
## Remove existing file. Requires absolute path.
func remove_file(path: String) -> Error:
	if !FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		return ERR_FILE_CANT_WRITE
	
	file_removed.emit(path)
	return OK

## Move existing file from A to B. Requires absolute paths
func move_file(old_path: String, new_path: String, safe: bool = true) -> Error:
	if old_path == new_path:
		return ERR_ALREADY_EXISTS

	var err := copy_file(old_path, new_path, safe)
	if err != OK:
		return err
	remove_file(old_path)
	return OK

## generates a unique file path based on a file's original name.
static func get_unique_file_path(base_path: String, filename: String) -> String:
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