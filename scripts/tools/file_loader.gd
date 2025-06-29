class_name FileLoader extends Node

var _queue: Array[String] = []
var _cache: Dictionary[String, FileData] = {}
var _is_working := false

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
	clear_queue()
	_queue.assign(paths)

func _process(_delta: float) -> void:
	if _queue.size() > 0:
		var temp_queue := []
		for i in batch_size:
			if _queue.is_empty():
				break
			temp_queue.append(_queue.pop_front())
		
		for path in temp_queue:
			_load_file(path)

		if _queue.size() == 0:
			queue_cleared.emit()
			queue_complete.emit()

func _load_file(path: String) -> void:
	if path in _cache:
		file_loaded.emit(path, _cache[path])
		return
	var file_data := FileData.new(path)
	file_data.modified = FileAccess.get_modified_time(path)
	file_data.size = FileAccess.get_file_as_bytes(path).size()
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

func is_working() -> bool:
	return _is_working
