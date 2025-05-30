class_name ImageResolver extends Node

var project_data: ProjectData

func get_hash_for_path(path: String) -> String:
	path = ProjectTools.normalize_path
