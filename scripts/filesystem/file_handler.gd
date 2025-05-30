class_name FileHandler extends Object

signal file_moved(old_path: String, new_path: String)
signal file_removed(path: String)

## Move existing file from A to B. Requires absolute paths
func move_file(old_path: String, new_path: String) -> void:
	if old_path == new_path:
		return

	if !FileAccess.file_exists(old_path):
		push_error("File does not exist: " + old_path)
		return
	if FileAccess.file_exists(new_path):
		push_error("About to overwrite existing file: " + new_path)
		return
	
	var err := DirAccess.copy_absolute(old_path, new_path)
	if err != OK:
		push_error("Failed to move file: err ", err)
		return
	
	err = DirAccess.remove_absolute(old_path)
	if err != OK:
		push_error("failed to remove original file: ", old_path)
	
	file_moved.emit(old_path, new_path)

## Remove existing file. Requires absolute path.
func remove_file(path: String) -> void:
	if !FileAccess.file_exists(path):
		return
	
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		push_error("Failed to remove file: ", path)
	
	file_removed.emit(path)
