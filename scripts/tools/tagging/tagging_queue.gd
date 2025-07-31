class_name TaggingQueue extends Node

@export var project: DatabaseAdapter
@export var image_hasher: ImageImportService

var _queue: Array[QueueItem] = []

@export_range(1, 20, 1) var batch_size: int = 1

func _ready() -> void:
	pass

func enqueue(file: String, tags: Array[StringName]) -> void:
	var item := QueueItem.new(file, tags.duplicate())
	_queue.append(item)

func _process(_delta: float) -> void:
	if _queue.is_empty():
		return
	var item: QueueItem = _queue.pop_front()
	var file_hash := project.get_hash_for_path(item.file)
	if file_hash.is_empty():
		file_hash = image_hasher.hash_file(item.file)

	project.add_image(file_hash, item.file, "", {})
	project.multi_tag_image(file_hash, item.tags)

	item.free()
