class_name ImageDB extends RefCounted

var _db: Dictionary[String, ImageData] = {}
var _index: Dictionary = {}

signal images_updated
signal image_added(image_hash: String)
signal image_changed(image_hash: String)
signal image_moved(from: String, to: String)
signal image_removed(image_hash: String)

func _init() -> void:
	_db = {}
	_index = {}

func register_image(path: String, image_hash: String) -> void:
	if image_hash in _db:
		return
	
	var image_data := ImageData.new()
	image_data.last_path = path
	
	_db[image_hash] = image_data
	_index[path] = image_hash
	
	image_added.emit(image_hash)

func add_tag_to_image(image_hash: String, tag: StringName) -> void:
	if !_db.has(image_hash):
		return
	var image_data := get_image_data(image_hash)
	if image_data.tags.has(tag):
		return
	image_data.tags.append(tag)
	image_changed.emit(image_hash)

func remove_tag_from_image(image_hash: String, tag: StringName) -> void:
	if !_db.has(image_hash):
		return
	var image_data := get_image_data(image_hash)
	if !image_data.tags.has(tag):
		return
	image_data.tags.erase(tag)
	image_changed.emit(image_hash)

func get_images() -> PackedStringArray:
	return _db.keys()

func update_image_path(image_hash: String, path: String) -> void:
	var old_path: = ""
	if !_db.has(image_hash):
		register_image(path, image_hash)
		old_path = _db[image_hash].last_path
	_db[image_hash].last_path = path
	_index[path] = image_hash
	if old_path:
		_index.erase(old_path)

#region image data
func has(image_hash: String) -> bool:
	return _db.has(image_hash)

func get_image_data(image_hash: String) -> ImageData:
	if image_hash in _db:
		return _db[image_hash].duplicate()
	return null

func get_path_for_hash(image_hash: String) -> String:
	if _db.has(image_hash):
		return get_image_data(image_hash).last_path
	return ""

func get_hash_for_path(image_path: String) -> String:
	var image_hash: String = _index[image_path]
	
	image_hash = ProjectManager.image_hasher.hash_image(image_path)
	update_image_path(image_hash, image_path)
	_index[image_path] = image_hash
	return image_hash
#endregion

#region index
func index_image(file_path: String, image_hash: String) -> void:
	_index[file_path] = image_hash

func clear_index() -> void:
	_index = {}

func get_index() -> Dictionary:
	return _index.duplicate()

func sort_index() -> void:
	_index.sort()
#endregion