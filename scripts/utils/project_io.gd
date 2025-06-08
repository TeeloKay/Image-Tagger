class_name ProjectIO extends RefCounted

func save_project(project: ProjectData) -> void:
	
	var save_path := project.project_path.path_join(".artmeta").path_join("project.json")	
	var project_data = project.serialize()

	var json := JSON.stringify(project_data, "\t")
	var dir = DirAccess.open(project.project_path)
	if !dir.dir_exists(".artmeta"):
		dir.make_dir(".artmeta")
		
	var file = FileAccess.open(save_path,FileAccess.WRITE)	
	if file:
		file.store_string(json)
		file.close()
	else:
		push_error("Failed to save project data to %s" % save_path)
	
	print("project saved")

func load_project(path: String) -> ProjectData:
	var project := ProjectData.new()
	project.project_path = path
	
	var project_path := path.path_join(".artmeta").path_join("project.json")
	var file = FileAccess.open(project_path,FileAccess.READ)
	if !file:
		push_error("Failed to open project data at %s" % project_path)
		return project
	
	var content = file.get_as_text()
	var result = JSON.parse_string(content)
	if !result:
		push_error("JSON parsing failed for %s" % project_path)
		return project
	
	project.deserialize(result)
	print("project loaded")
	return project
