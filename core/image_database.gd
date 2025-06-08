class_name ImageDB extends RefCounted

const IMAGES: String = "images"
const INDEX: String = "index"

var _db: Dictionary[String, ImageData] = {}
var _index: Dictionary = {}

signal image_registered(image_hash: String)
signal image_changed(image_hash: String)
signal image_moved(from: String, to: String)

func _init() -> void:
	_db = {}
	_index = {}

## add image to database.
func register_image(path: String, image_hash: String) -> void:
	if image_hash in _db:
		return
	
	var image_data := ImageData.new()
	image_data.last_path = path
	
	_db[image_hash] = image_data
	_index[path] = image_hash
	
	image_registered.emit(image_hash)

## add a tag to an image.
func add_tag_to_image(image_hash: String, tag: StringName) -> void:
	if !_db.has(image_hash):
		return
	var image_data := get_image_data(image_hash)
	if image_data.tags.has(tag):
		return
	image_data.tags.append(tag)
	image_changed.emit(image_hash)

## removes a tag from an image.
func remove_tag_from_image(image_hash: String, tag: StringName) -> void:
	if !_db.has(image_hash):
		return
	var image_data := get_image_data(image_hash)
	if !image_data.tags.has(tag):
		return
	image_data.tags.erase(tag)
	image_changed.emit(image_hash)

## update latest image path.
func update_image_path(image_hash: String, new_path: String) -> void:
	var old_path: = ""
	if !_db.has(image_hash):
		register_image(new_path, image_hash)
		old_path = _db[image_hash].last_path
	_db[image_hash].last_path = new_path
	_index[new_path] = image_hash
	if old_path:
		_index.erase(old_path)
	image_moved.emit(old_path, new_path)

#region image data
func get_images() -> PackedStringArray:
	return _db.keys()

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

#region serialization
func serialize() -> Dictionary:
	var data := {}
	data[IMAGES] 	= {}
	data[INDEX] 	= {}
	for image_hash in _db:
		data[IMAGES][image_hash] = get_image_data(image_hash).serialize()
	for path in _index:
		data[INDEX][path] = _index[path]
	return data

func deserialize(data: Dictionary) -> void:
	if data.has(IMAGES) && data.has(INDEX):
		for image_hash in data[IMAGES]:
			var image_data := ImageData.new()
			image_data.deserialize(data[IMAGES][image_hash])
			_db[image_hash] = image_data
		for path in data[INDEX]:
			_index[path] = data[INDEX][path]
#endregion