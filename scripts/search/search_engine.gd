class_name SearchEngine extends Object

var accepted_types := ["png", "jpg", "jpeg", "webp", "gif"]
var _search_chain: SearchHandler

signal search_completed(results: Array[SearchResult])

func _init() -> void:
	_search_chain = SearchByTag.new()

func search_images(query: SearchQuery) -> Array[SearchResult]:
	var hashes: Array[String] = []
	var results: Array[SearchResult] = []
	var root := ProjectManager.current_project.project_path
	var project := ProjectManager.current_project
	var q := ProjectTools.sanitize_tag(query.text)
	
	print(q)
	_recursive_search(root, q, results)
	for result in hashes:
		var path := project.get_path_for_hash(result)
		results.append(SearchResult.new(path, result))	
	search_completed.emit(results)
	return results

func _recursive_search(dir_path: String, query: String, out_results: Array[SearchResult]) -> void:
	var dir := DirAccess.open(dir_path)
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
			_recursive_search(full_path, query, out_results)
			file_name = dir.get_next()
			continue
		
		var name_match := file_name.to_lower().contains(query)
		var tag_match := false
		var hash_val := ProjectManager.current_project.get_hash_for_path(rel_path)
		if !hash_val:
			file_name = dir.get_next()
			continue
			
		var tags := ProjectManager.current_project.get_tags_for_hash(hash_val)
		for tag in tags:
			if tag.contains(query):
				tag_match = true
				break

		if name_match || tag_match:
			var result := SearchResult.new(rel_path, hash_val)
			out_results.append(result)
		file_name = dir.get_next()
	dir.list_dir_end()

func _inclusive_tag_search(tags: Array[StringName], out_results: Array[String]) -> void:
	for tag in tags:
		var hashes := Array(ProjectManager.current_project.get_tag_data(tag).hashes)
		if out_results.is_empty():
			out_results.assign(hashes)
			continue
		out_results = get_array_intersection(hashes, out_results.duplicate())
		
func get_array_intersection(a: Array, b: Array) -> Array:
	var dict := {}
	for item: String in a:
		dict[item] = true
	
	var result := []
	for item: String in b:
		if dict.has[item]:
			result.append(item)
	return result
