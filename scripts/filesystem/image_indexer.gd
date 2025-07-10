class_name ImageIndexer extends Node

@export var project: ProjectData:
	set = set_project
func _ready() -> void:
	pass

func index_project() -> void:
	_scan_directory(project.project_path)
	_update_index_hashes()
	
func _scan_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir() && !file_name.begins_with("."):
			_scan_directory(path.path_join(file_name))
			file_name = dir.get_next()
			continue
		if ImageUtil.is_valid_image(file_name):
			var full_path := path.path_join(file_name)
			var rel_path := project.to_relative_path(full_path)
			project.index_image_path(rel_path, "")

		file_name = dir.get_next()
	dir.list_dir_end()

func _update_index_hashes() -> void:
	for image_hash in project.get_images():
		if image_hash == "":
			continue
		var data: ImageData = project.get_image_data(image_hash)
		if data == null:
			continue
		if data.last_path in project.get_index():
			project.index_image_path(data.last_path, image_hash)

func set_project(_project: ProjectData) -> void:
	project = _project
