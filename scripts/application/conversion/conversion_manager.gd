class_name ConversionManager extends Node

var _queue: Array[ConversionJob] = []
var _current_job_index := -1
var _converters: Dictionary[String, ImageConverter] = {}

signal conversion_started
signal conversion_ended
signal conversion_progress(progress: float)
signal conversion_failed(image_path: String, error: Error)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func enqueue_job(image_path: String, target_format: String) -> void:
	print(image_path)
	if image_path.get_extension() == target_format:
		return
	_queue.append(ConversionJob.new(image_path, target_format))

func enqueue_jobs(image_paths: PackedStringArray, target_format: String) -> void:
	for path in image_paths:
		enqueue_job(path, target_format)

func start_processing() -> void:
	if _queue.is_empty():
		return
	_current_job_index = 0
	conversion_started.emit()
	_process_next_job()

func _process_next_job() -> void:
	#TODO: break this method up into functions
	print("processing queue")
	if _current_job_index >= _queue.size() || _current_job_index == -1:
		conversion_ended.emit()
		_queue.clear()
		_current_job_index = -1
		return

	conversion_progress.emit(float(_current_job_index) / float(_queue.size()))

	var job := _queue[_current_job_index]
	var converter: ImageConverter = _converters.get(job.target_format, null)

	if !converter:
		push_error("Cannot convert image '%s', converter for type '%s' not registered." % [job.image_path, job.target_format])
		conversion_failed.emit(job.image_path, ERR_INVALID_PARAMETER)
		_current_job_index += 1
		_process_next_job()
	
	print("converting: ", job.image_path)
	var orig_hash := ProjectContext.importer.hash_file(job.image_path)
	print(orig_hash)
	
	var orig_info := ProjectContext.db.get_image_info(orig_hash)
	print(orig_info)
	print("obtained data. or not.")

	var output_path := job.output_path
	print(output_path)
	output_path = FileService.make_unique_file_path(output_path)

	var err := converter.convert(job.image_path, output_path)
	if err != OK:
		push_error("Failed to convert image '%s' with error code %d" % [job.image_path, err])
		conversion_failed.emit(job.image_path, output_path)
		_current_job_index += 1
		_process_next_job()
	
	var new_hash := ProjectContext.importer.hash_file(output_path)

	if orig_info:
		ProjectContext.db.delete_image(orig_hash)
		ProjectContext.db.add_image(new_hash, output_path, "", {})
		ProjectContext.db.multi_tag_image(new_hash, orig_info.tags)
		ProjectContext.db.set_image_favorited(new_hash, orig_info.favorited)

	FileService.remove_file(job.image_path)
	_current_job_index += 1
	_process_next_job()
	
func register_converter(type: String, converter: ImageConverter) -> void:
	if _converters.has(type):
		return
	_converters[type] = converter


class ConversionJob:
	var image_path: String
	var target_format: String
	var output_path: String

	func _init(path: String, format: String) -> void:
		image_path = path
		target_format = format
		output_path = image_path.replace(image_path.get_extension(), target_format)