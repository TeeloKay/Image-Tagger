class_name SearchByTag extends SearchHandler

func search(query: SearchQuery, out_results: Array) -> void:
	if !query.inclusive_tags.is_empty():
		for tag in query.inclusive_tags:
			var hashes := Array(project_data.get_tag_data(tag).hashes)
			if out_results.is_empty():
				out_results.assign(hashes)
			out_results = _get_array_intersection(hashes, out_results.duplicate())
	if _next_handler != null:
		_next_handler.search(query, out_results)

func _get_array_intersection(a: Array, b: Array) -> Array:
	var dict := {}
	for item: String in a:
		dict[item] = true

	var result := []
	for item: String in b:
		if dict.has[item]:
			result.append(item)
	return result
