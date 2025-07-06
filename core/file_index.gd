class_name FileIndex extends Resource

# relative file path -- hash
var _index: Dictionary[String, String] = {}

#region core functions
func add(file: String, file_hash: String) -> Error:
    if file.is_empty():
        return ERR_FILE_NOT_FOUND
    
    _index[file] = file_hash
    return OK

func update_file(old_path: String, new_path: String) -> void:
    if !has(old_path):
        return

    var file_hash := _index[old_path]
    _index.erase(old_path)
    add(new_path, file_hash)

func has(file: String) -> bool:
    return _index.has(file)

func get_hash_for_file(file: String) -> String:
    if !has(file):
        return ""
    return _index[file]

func clear() -> void:
    _index.clear()

func get_index() -> Dictionary:
    return _index.duplicate()
#endregion

#region serialization
func serialize() -> Dictionary:
    return _index.duplicate()

func deserialize(data: Dictionary) -> void:
    for path in data:
        _index[path] = str(data[path])
#endregion