class_name FileDataHandler extends Object

enum SortMode {
	SORT_BY_NAME_ASC,
	SORT_BY_NAME_DESC,
	SORT_BY_SIZE_ASC,
	SORT_BY_SIZE_DESC,
	SORT_BY_DATE_ASC,
	SORT_BY_DATE_DESC,
	SORT_BY_TYPE_ASC,
	SORT_BY_TYPE_DESC
}

var sort_mode: SortMode = SortMode.SORT_BY_NAME_ASC:
	set = set_sort_mode

## Array of file paths in the current directory or search result.
var _files: Array[String] = []
## Dictionary of image meta data.
var _file_data: Dictionary[String, FileData] = {}

func get_files() -> Array[String]:
	return _files.duplicate()

func get_files_filtered(type_filter: Array) -> PackedStringArray:
	if type_filter.is_empty():
		return PackedStringArray(_files)
	var filtered_files: PackedStringArray = []
	for file in _files:
		if file.get_extension() in type_filter:
			filtered_files.append(file)
	return filtered_files

func assign_files(files: PackedStringArray) -> void:
	_files.assign(files)

func get_file_data(file: String) -> FileData:
	if _file_data.has(file):
		return _file_data[file]
	return null

func add_file(file: String) -> void:
	if file in _files:
		return
	_files.append(file)

func remove_file(file: String) -> void:
	print(file)
	var index := _files.find(file)
	if index == -1:
		return
	_files.remove_at(index)
	if file in _file_data:
		_file_data.erase(file)

func register_file(file: String, file_data: FileData) -> void:
	add_file(file)
	_file_data[file] = file_data

func sort_files() -> void:
	match sort_mode:
		SortMode.SORT_BY_NAME_ASC:
			_files.sort_custom(_sort_by_name_asc)
		SortMode.SORT_BY_NAME_DESC:
			_files.sort_custom(_sort_by_name_desc)
	
		SortMode.SORT_BY_SIZE_ASC:
			_files.sort_custom(_sort_by_size_asc)
		SortMode.SORT_BY_SIZE_DESC:
			_files.sort_custom(_sort_by_size_desc)
	
		SortMode.SORT_BY_DATE_ASC:
			_files.sort_custom(_sort_by_date_asc)
		SortMode.SORT_BY_DATE_DESC:
			_files.sort_custom(_sort_by_date_desc)
		
		SortMode.SORT_BY_TYPE_ASC:
			_files.sort_custom(_sort_by_extension_asc)
		SortMode.SORT_BY_TYPE_DESC:
			_files.sort_custom(_sort_by_extension_desc)

#region Sort methods
func _sort_by_name_asc(a: String, b: String) -> bool:
	return _file_data[a].name < _file_data[b].name

func _sort_by_name_desc(a: String, b: String) -> bool:
	return _file_data[a].name > _file_data[b].name

func _sort_by_size_asc(a: String, b: String) -> bool:
	var size_a := _file_data[a].size
	var size_b := _file_data[b].size
	return size_a < size_b if size_a != size_b else _sort_by_name_asc(a, b)

func _sort_by_size_desc(a: String, b: String) -> bool:
	var size_a := _file_data[a].size
	var size_b := _file_data[b].size
	return size_a > size_b if size_a != size_b else _sort_by_name_desc(a, b)

func _sort_by_date_asc(a: String, b: String) -> bool:
	var date_a := _file_data[a].modified
	var date_b := _file_data[b].modified
	return date_a < date_b if date_a != date_b else _sort_by_name_asc(a, b)

func _sort_by_date_desc(a: String, b: String) -> bool:
	var date_a := _file_data[a].modified
	var date_b := _file_data[b].modified
	return date_a > date_b if date_a != date_b else _sort_by_name_desc(a, b)

func _sort_by_extension_asc(a: String, b: String) -> bool:
	var type_a := _file_data[a].get_extension()
	var type_b := _file_data[b].get_extension()
	return type_a < type_b if type_a != type_b else _sort_by_name_asc(a, b)

func _sort_by_extension_desc(a: String, b: String) -> bool:
	var type_a := _file_data[a].get_extension()
	var type_b := _file_data[b].get_extension()
	return type_a > type_b if type_a != type_b else _sort_by_name_desc(a, b)

#endregion

func set_sort_mode(mode: SortMode) -> void:
	sort_mode = mode

func clear() -> void:
	_files.clear()

func reset() -> void:
	_files.clear()
	_file_data.clear()

func get_file_count() -> int:
	return _files.size()

func get_file_at_index(idx: int) -> String:
	if idx >= 0 && idx < _files.size():
		return _files[idx]
	return ""

func file_is_registered(file: String) -> bool:
	return _file_data.has(file)
