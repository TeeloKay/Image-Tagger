class_name ImageHasher extends RefCounted

const CHUNK_SIZE := 1024
var _queue: Array[String]

var _thread: Thread
var _mutex: Mutex
var _semaphore: Semaphore

var _exit_thread: bool = false

signal file_hashed(path: String)

func initialize() -> void:
	_thread = Thread.new()
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()z

	_thread.start(_thread_process)

func hash_image(abs_path: String) -> String:
	var file_hash := _hash_file(abs_path)

	file_hashed.emit(abs_path,file_hash)
	return _hash_file(abs_path)

func add_file_to_queue(path: String) -> void:
	if !FileAccess.file_exists(path):
		return
	
func _thread_process() -> void:
	while !_exit_thread:
		_semaphore.wait()
		if _exit_thread:
			break
	
		_mutex.lock()
		var path = _queue.pop_front()
		if !FileAccess.file_exists(path):
			continue

		var file_hash := _hash_file(path)
		if !file_hash.is_empty:
			file_hashed.emit(path, file_hash)

		_mutex.unlock()

func _hash_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if !file:
		return ""
	
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)

	while file.get_position() < file.get_length():
		var remaining = file.get_length() - file.get_position()
		ctx.update(file.get_buffer(min(remaining, CHUNK_SIZE)))

	file.close()
	var res := ctx.finish()
	print(res.hex_encode(),Array(res))
	return res.hex_encode()
