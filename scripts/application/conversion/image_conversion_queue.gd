extends Node
class_name ImageConversionQueue

var _queue: Array[QueueJob] = []
var is_processing := false

var _image_converter: ImageConverter

signal image_converted(original_path: String, new_path: String, new_hash: String)
signal queue_started(total_jobs: int)
signal job_started(index: int, total_jobs: int)
signal queue_finished()

func _ready() -> void:
	_image_converter = ImageConverter.new()
	_image_converter.add_strategy("jpeg", ToJPEGStrategy.new())
	_image_converter.add_strategy("png", ToPNGStrategy.new())
	_image_converter.add_strategy("webp", ToWebPStrategy.new())

func enqueue_image_conversion(image_path: String, type: String) -> void:
	if !_image_converter.strategies.has(type):
		return
	_queue.append(QueueJob.new(image_path, type))
	
func process_queue() -> void:
	if is_processing || _queue.is_empty():
		return
	
	is_processing = true
	var job := _queue.pop_front() as QueueJob
	await _process_job(job)

	if !_queue.is_empty():
		call_deferred("process_queue")

func _process_job(job: QueueJob) -> void:
	var new_path := _image_converter.convert(job.type, job.path)

	var new_hash := ProjectContext.image_import_service.hash_file(new_path)
	var original_hash := ProjectContext.database_adapter.get_hash_for_path(job.path)

	var original_info := ProjectContext.database_adapter.get_image_info(original_hash)
	
	ProjectContext.database_adapter.add_image(new_hash, new_path, "", {})
	ProjectContext.database_adapter.multi_tag_image(new_hash, original_info.tags)

class QueueJob:
	var path: String
	var type: String

	func _init(path: String, type: String) -> void:
		self.path = path
		self.type = type