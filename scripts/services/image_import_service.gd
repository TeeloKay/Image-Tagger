class_name ImageImportService extends Node

const CHUNK_SIZE := 8192
const FINGERPRINT_CHUNK_SIZE := 8192
const MAX_FILE_SIZE := 10000000

@export_range(1, 100, 1) var batch_size: int = 1

var _queue: Array[String]
var _output_queue: Dictionary[String, String] = {}

var _thread: Thread
var _mutex: Mutex
var _semaphore: Semaphore

var _exit_thread: bool = false

signal file_hashed(path: String, file_hash: String)

func _ready() -> void:
	_thread = Thread.new()
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()

	_thread.start(_thread_process)

func hash_file(abs_path: String) -> String:
	var file_hash := _hash_file(abs_path)
	file_hashed.emit(abs_path, file_hash)
	return file_hash

func add_file_to_queue(path: String) -> void:
	_mutex.lock()
	if _queue.has(path):
		_mutex.unlock()
		return
	_queue.push_back(path)
	_mutex.unlock()
	_semaphore.post()
	
func _thread_process() -> void:
	while !_exit_thread:
		_semaphore.wait()
		if _exit_thread:
			break

		var batch := []
		_mutex.lock()
		for i in batch_size:
			if _queue.is_empty():
				break
			batch.append(_queue.pop_front())
		_mutex.unlock()

		for path: String in batch:
			# while technically we've already checked this, we check again
			# just in case the file no longer exists.
			if !FileAccess.file_exists(path):
				continue

			var file_hash := _hash_file(path)
			if !file_hash.is_empty():
				_mutex.lock()
				_output_queue[path] = file_hash
				_mutex.unlock()

		_mutex.unlock()


# Main thread process
func _process(_delta: float) -> void:
	_mutex.lock()
	if !_output_queue.is_empty():
		for file: String in _output_queue.keys():
			file_hashed.emit(file, _output_queue[file])
		_output_queue.clear()

	_mutex.unlock()

func _hash_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if !file:
		return ""
	if file.get_error() != OK:
		push_error(file.get_error())
		return ""
	
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)

	if file.get_length() > MAX_FILE_SIZE:
		push_error("File is too large.")
		return ""

	print("starting hashing")
	while file.get_position() < file.get_length():
		var remaining := file.get_length() - file.get_position()
		var buffer := file.get_buffer(min(remaining, CHUNK_SIZE))
		ctx.update(buffer)

	file.close()
	var res := ctx.finish()

	return res.hex_encode()

func fingerprint_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if !file:
		return ""
	
	var file_size := file.get_length()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)

	ctx.update(file.get_buffer(min(FINGERPRINT_CHUNK_SIZE, file_size)))

	return ctx.finish().hex_encode()

func _exit_tree() -> void:
	_mutex.lock()
	_exit_thread = true
	_mutex.unlock()

	_semaphore.post()

	_thread.wait_to_finish()
