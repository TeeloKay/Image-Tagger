class_name ImageManager extends RefCounted

var _image_db: Dictionary[String, ImageInfo] = {}
var _path_to_hash: Dictionary = {}

signal images_updated
signal image_added(hash_val: String)
signal image_changed(hash_val: String)
signal image_moved(from: String, to: String)
signal image_removed(hash_val: String)

func _init() -> void:
	_image_db = {}
	_path_to_hash = {}

func register_image(path: String, hash_val: String) -> void:
	if hash_val in _image_db:
		return
	
	var image_info := ImageInfo.new()
	image_info.last_path = path
	
	_image_db[hash_val] = image_info
	_path_to_hash[path] = hash_val
	
	image_added.emit(hash_val)

func add_tag_to_image(hash_val: String, tag: StringName) -> void:
	if !_image_db.has(hash_val):
		return
	var info := get_info_for_hash(hash_val)
	if info.tags.has(tag):
		return
	info.tags.append(tag)
	image_changed.emit(hash_val)

func remove_tag_from_image(hash_val: String, tag: StringName) -> void:
	if !_image_db.has(hash_val):
		return
	var info := get_info_for_hash(hash_val)
	if !info.tags.has(tag):
		return
	info.tags.erase(tag)
	image_changed.emit(hash_val)

func get_images() -> PackedStringArray:
	return _image_db.keys()

func update_hash_path(hash_val: String, path: String) -> void:
	var old_path := _image_db[hash_val].last_path
	_image_db[hash_val].last_path = path
	_path_to_hash[path] = hash_val
	_path_to_hash.erase(old_path)

func get_hash_for_path(image_path: String) -> String:
	if _path_to_hash.has(image_path):
		var hash_val = String(_path_to_hash[image_path])
		if hash_val != &"":
			return hash_val
	
	var hash_val = ProjectManager.image_hasher.hash_image(image_path)
	_path_to_hash[image_path] = hash_val
	return hash_val

func get_path_for_hash(hash_val: String) -> String:
	if _image_db.has(hash_val):
		return get_info_for_hash(hash_val).last_path
	return ""

func get_info_for_hash(hash_val: String) -> ImageInfo:
	if !has(hash_val):
		return ImageInfo.new()
	return _image_db.get(hash_val, null)

func index_image(file_path: String, hash: String = "") -> void:
	if !file_path in _path_to_hash:
		_path_to_hash[file_path] = hash

func has(hash_val: String) -> bool:
	return _image_db.has(hash_val)

func clear_index() -> void:
	_path_to_hash = {}

func get_index() -> Dictionary:
	return _path_to_hash.duplicate()

func sort_index() -> void:
	_path_to_hash.sort()