class_name FileLoader extends Node

var _queue: Array[String] = []
var _cache: Dictionary[String, FileData] = {}

@export_range(1, 1024, 1) var max_cache_size: int = 512
@export_range(1, 100, 1, "or_greater") var batch_size: int = 12

signal file_loaded(path: String, data: FileData)
signal queue_cleared
signal cache_cleared
signal queue_complete

## add singular file to queue.
func add_file_to_queue(path: String) -> void:
	_queue.append(path)

## Add series of file paths to queue.
func populate_queue(paths: Array[String]) -> void:
	print(paths)
	clear_queue()
	_queue.assign(paths)
	print(_queue.size())

func _process(_delta: float) -> void:
	if _queue.size() > 0:
		var temp_queue := []
		print(temp_queue)
		for i in batch_size:
			if _queue.is_empty():
				break
			temp_queue.append(_queue.pop_front())
		
		for path in temp_queue:
			_load_file(path)
		if _queue.size() == 0:
			queue_cleared.emit()

func _load_file(path: String) -> void:
	if path in _cache:
		file_loaded.emit(path, _cache[path])
		return
	var file_name := path.get_file()
	var modified := FileAccess.get_modified_time(path)
	var size := FileAccess.get_file_as_bytes(path).size()
	print(path)
	print("file_name: modified ", modified, ", size ", size)
	var file_data := FileData.new(file_name, modified, size)
	_add_file_data_to_cache(path, file_data)

	file_loaded.emit(path, file_data)


func _add_file_data_to_cache(path: String, file_data: FileData) -> void:
	if _cache.size() >= max_cache_size:
		_cache.erase(_cache.keys()[0])
	_cache[path] = file_data

## clears the internal queue.
func clear_queue() -> void:
	_queue.clear()
	queue_cleared.emit()

## Empties the internal cache.
func clear_cache() -> void:
	_cache.clear()
	cache_cleared.emit()
