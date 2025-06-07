class_name ImageIndexer extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func index_project(project: ProjectData) -> void:
	_scan_directory(project.project_path, project)
	project.image_manager._path_to_hash.sort()
	
func _scan_directory(path: String, project: ProjectData) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir() && !file_name.begins_with("."):
			_scan_directory(path.path_join(file_name), project)
			file_name = dir.get_next()
			continue
		if ImageUtil.is_valid_image(file_name):
			var full_path = path.path_join(file_name)
			var rel_path = ProjectManager.to_relative_path(full_path)
			project.index_image_path(rel_path)

		file_name = dir.get_next()
	dir.list_dir_end()
