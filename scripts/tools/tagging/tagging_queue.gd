class_name TaggingQueue extends Node

var project_data: ProjectData
var image_hasher: ImageHasher

var _queue: Array[QueueItem] = []

@export_range(1, 20, 1) var batch_size: int = 1

func _ready() -> void:
	pass

func enqueue(file: String, tags: Array[StringName]) -> void:
	print(tags)
	var item := QueueItem.new(file, tags.duplicate())
	_queue.append(item)

func _process(_delta: float) -> void:
	if _queue.is_empty():
		return
	var item: QueueItem = _queue.pop_front()
	print(item.tags)
	var file_hash := project_data.get_hash_for_path(item.file)
	if file_hash.is_empty():
		file_hash = image_hasher.hash_file(item.file)
	print(item.file, ": ", file_hash)

	project_data.add_image(file_hash, item.file)
	project_data.add_tags_for_hash(file_hash, item.tags)
