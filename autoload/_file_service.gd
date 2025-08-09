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

## Converts file path into a unique path based on the original file's name.
func make_unique_file_path(file_path: String) -> String:
	if !FileAccess.file_exists(file_path):
		return file_path

	var directory_path := file_path.get_base_dir()
	var file_name := file_path.get_file().get_basename()
	var dot_ext := "." + file_path.get_extension()

	var file_exists := true
	var counter := 1

	var new_name := ""

	## We loop over the directory trying to find an iteration that hasn't been implemented yet.
	while file_exists:
		new_name = "%s_%d" % [file_name, counter]
		file_path = directory_path.path_join(new_name + dot_ext)
		file_exists = FileAccess.file_exists(file_path)
		if file_exists:
			counter += 1
	
	return file_path