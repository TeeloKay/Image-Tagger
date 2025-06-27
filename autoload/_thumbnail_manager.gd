extends Node

var _queue: Array[String] = []
var _cache: Dictionary[String,Texture2D] = {}
var _pending_results: Dictionary[String, Texture2D] = {}

var images_per_batch: int 	= 6
var max_cache_size: int 	= 4096

var _semaphore: Semaphore	= null
var _thread: Thread 		= null
var _mutex: Mutex			= null

var exit_thread: bool		= false

signal thumbnail_ready(path: String, thumbnail: Texture2D)
signal queue_cleared

func _ready() -> void:
	_semaphore 	= Semaphore.new()
	_thread 	= Thread.new()
	_mutex		= Mutex.new()
	_thread.start(_thread_process)

func queue_thumbnail(abs_path: String) -> void:
	_mutex.lock()
	if abs_path in _cache:
		var thumb := _cache[abs_path]
		_mutex.unlock()
		thumbnail_ready.emit(abs_path,thumb)
		return
	if abs_path in _queue:
		_mutex.unlock()
		return
	_queue.append(abs_path)
	_mutex.unlock()
	_semaphore.post()

func _thread_process() -> void:
	while !exit_thread:
		_semaphore.wait()
		if exit_thread:
			break
		
		var local_queue := []

		_mutex.lock()
		for i in images_per_batch:
			if _queue.is_empty():
				break
			local_queue.append(_queue.pop_front())
		_mutex.unlock()

		for path in local_queue:
			var thumbnail = get_image(path)
			if thumbnail == null:
				thumbnail = ImageUtil.generate_thumbnail_from_path(path)
				if thumbnail:
					_mutex.lock()
					_add_image_to_cache(path,thumbnail)
					_mutex.unlock()
			if thumbnail:
				_mutex.lock()
				_pending_results[path] = thumbnail
				_mutex.unlock()

func _process(_delta: float) -> void:
	_mutex.lock()
	for result in _pending_results:
		thumbnail_ready.emit(result, _cache[result])
	_pending_results.clear()
	_mutex.unlock()
		
func rebuild_thumbnails(paths: PackedStringArray, clear_cache := true) -> void:
	if clear_cache:
		clear()
	for path in paths:
		queue_thumbnail(path)

func has(abs_path: String) -> bool:
	return _cache.has(abs_path)

func get_image(abs_path: String) -> Texture2D:
	return _cache.get(abs_path,null)

func _add_image_to_cache(abs_path: String, texture: Texture2D) -> void:
	if _cache.size() >= max_cache_size:
		_cache.erase(_cache.keys()[0])
	_cache[abs_path] = texture

func clear() -> void:
	_mutex.lock()
	_cache.clear()
	_queue.clear()
	_mutex.unlock()
	queue_cleared.emit()

func clear_queue() -> void:
	_mutex.lock()
	_queue.clear()
	_mutex.unlock()
	queue_cleared.emit()

func _exit_tree() -> void:
	exit_thread = true
	_semaphore.post()
	_thread.wait_to_finish()
