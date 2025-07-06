class_name TaggingQueue extends Node

var project_data: ProjectData
var image_hasher: ImageHasher

@export var _queue: Array[String] = []
@export var _data: Dictionary[String, Array] = {}

func enqueue(file: String, tags: Array[StringName]) -> void:
	if file in _queue && file in _data:
		_data[file].append_array(tags)
		return
	_queue.append(file)
	_data[file] = tags

func process_queue() -> void:
	while !_queue.is_empty():
		var path := str(_queue.pop_front())
		var file_hash := project_data.get_hash_for_path(path)
		if file_hash.is_empty():
			file_hash = image_hasher.hash_file(path)
		print(path, ": ", file_hash)
		project_data.add_image(file_hash, path)
		project_data.set_tags_for_hash(file_hash, _data[path])

		_data.erase(path)
	ProjectManager.save_current_project()
