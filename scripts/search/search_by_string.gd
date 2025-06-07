class_name SearchByString extends SearchHandler

func search(query: SearchQuery, out_results: Array[String]) -> void:
    if !query.text.is_empty():
        var path = project_data.project_path
        _resursive_dir_search(path, query.text, out_results)

    if _next_handler != null:
        _next_handler.search(query, out_results)

func _resursive_dir_search(path: String, query: String, out_results: Array[String]) -> void:
    var dir = DirAccess.open(path)
    if dir == null:
        return
    dir.list_dir_begin()
    var name := dir.get_next()
    while name != "":
        if name.begins_with("."):
            name = dir.get_next()
            continue
        
        var full_path := path.path_join(name)
        var rel_path := ProjectManager.to_relative_path(full_path)

        if dir.current_is_dir():
            _resursive_dir_search(full_path, query, out_results)
            name = dir.get_next()
            continue
    
        if rel_path.match(query):
            out_results.append(rel_path)
        name = dir.get_next()
    dir.list_dir_end()

