class_name ImageManager extends RefCounted

var _image_db: Dictionary[String, ImageInfo] = {}
var _path_to_hash: Dictionary = {}

signal images_updated
signal image_added(hash: String)
signal image_changed(hash: String)
signal image_moved(from: String, to: String)
signal image_removed(hash: String)

func _init() -> void:
	_image_db = {}
	_path_to_hash = {}

func register_image(path: String, hash: String) -> void:
	if hash in _image_db:
		return
	
	var image_info := ImageInfo.new()
	image_info.last_path = path
	
	_image_db[hash] = image_info
	_path_to_hash[path] = hash
	
	image_added.emit(hash)

func add_tag_to_image(hash: String, tag: StringName) -> void:
	if !_image_db.has(hash):
		return
	var info := get_info_for_hash(hash)
	if info.tags.has(tag):
		return
	info.tags.append(tag)
	image_changed.emit(hash)

func remove_tag_from_image(hash: String, tag: StringName) -> void:
	if !_image_db.has(hash):
		return
	var info := get_info_for_hash(hash)
	if !info.tags.has(tag):
		return
	info.tags.erase(tag)
	image_changed.emit(hash)

func get_images() -> PackedStringArray:
	return _image_db.keys()

func update_hash_path(hash: String, path: String) -> void:
	var old_path := _image_db[hash].last_path
	_image_db[hash].last_path = path
	_path_to_hash[path] = hash
	_path_to_hash.erase(old_path)

func get_hash_for_path(image_path: String) -> String:
	if _path_to_hash.has(image_path):
		var hash = String(_path_to_hash[image_path])
		if hash != &"":
			return hash
	
	var hash = ProjectManager.image_hasher.hash_image(image_path)
	_path_to_hash[image_path] = hash
	return hash

func get_path_for_hash(hash: String) -> String:
	return _image_db.get(hash, "")

func get_info_for_hash(hash: String) -> ImageInfo:
	if !has(hash):
		return ImageInfo.new()
	return _image_db.get(hash,null)

func has(hash: String) -> bool:
	return _image_db.has(hash)
