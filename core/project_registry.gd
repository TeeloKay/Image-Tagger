class_name ProjectRegistry extends Resource

@export var projects: Array[String]

func register_project(path: String) -> void:
	if projects.has(path):
		return
	projects.push_front(path)

func remove_project(path: String) -> void:
	projects.erase(path)

func get_valid_projects() -> Array[String]:
	print(projects)
	var results : Array[String] = []
	for path in projects:
		print(path)
		if DirAccess.dir_exists_absolute(path):
			results.append(path)
	return results

func get_projects() -> Array[String]:
	return projects.duplicate()
