class_name SearchEngine extends Object

var accepted_types := ["png", "jpg", "jpeg", "webp", "gif"]

func search_images(query: String) -> Array[String]:
	var results :Array[String] = []
	var root := ProjectManager.current_project.project_path
	var q := ProjectManager.sanitize_tag(query)
	
	_recursive_search(root,q,results)
	print(results)
	return results

func _recursive_search(dir_path: String, query: String, out_results: Array[String]) -> void:
	var results := []
	
	var dir = DirAccess.open(dir_path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		
		var full_path := dir_path.path_join(file_name)
		var rel_path := ProjectManager.current_project.to_relative_path(full_path)
		
		if dir.current_is_dir():
			_recursive_search(full_path,query,out_results)
			file_name = dir.get_next()
			continue
		
		var name_match := file_name.to_lower().contains(query)
		var tag_match := false
		var hash := ProjectManager.current_project.get_hash_for_path(rel_path)
		if !hash:
			file_name = dir.get_next()
			continue
			
		var tags := ProjectManager.current_project.get_tags_for_hash(hash)
		for tag in tags:
			if tag.contains(query):
				tag_match = true
				break

		if name_match || tag_match:
			out_results.append(rel_path)
		file_name = dir.get_next()
	dir.list_dir_end()
