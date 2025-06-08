class_name ImageIndexer extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func index_project(project: ProjectData) -> void:
	_scan_directory(project.project_path, project)
	_update_index_hashes(project)
	project.image_manager._index.sort()
	
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
			project.index_image_path(rel_path, "")

		file_name = dir.get_next()
	dir.list_dir_end()

func _update_index_hashes(project: ProjectData) -> void:
	for image_hash in project.get_images():
		if image_hash == "":
			continue
		var info: ImageInfo = project.get_image_info(image_hash)
		if info == null:
			continue
		if info.last_path in project.image_manager._index:
			project.index_image_path(info.last_path, image_hash)
