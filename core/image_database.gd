class_name ImageDB extends RefCounted

var _db: Dictionary[String, ImageData] = {}

signal image_registered(image_hash: String)
signal image_changed(image_hash: String)
signal image_moved(from: String, to: String)

func _init() -> void:
	_db = {}

## add image to database.
func register_image(path: String, image_hash: String, image_data: ImageData = null) -> void:
	if image_hash in _db:
		return

	if image_data == null:
		image_data = ImageData.new()
	image_data.last_path = path
	
	_db[image_hash] = image_data
	
	image_registered.emit(image_hash)

func set_image_data(image_hash: String, image_data: ImageData) -> void:
	_db[image_hash] = image_data

## add a tag to an image.
func add_tag_to_image(image_hash: String, tag: StringName) -> void:
	if !_db.has(image_hash):
		return
	var image_data := _db[image_hash]
	if image_data.tags.has(tag):
		return
	image_data.tags.append(tag)
	image_changed.emit(image_hash)

## removes a tag from an image.
func remove_tag_from_image(image_hash: String, tag: StringName) -> void:
	if !_db.has(image_hash):
		return
	var image_data := _db[image_hash]
	if !image_data.tags.has(tag):
		return
	image_data.tags.erase(tag)
	image_changed.emit(image_hash)

## update latest image path.
func update_image_path(image_hash: String, new_path: String) -> void:
	var old_path := ""
	if !_db.has(image_hash):
		register_image(new_path, image_hash)
		old_path = _db[image_hash].last_path
	_db[image_hash].last_path = new_path
	image_moved.emit(old_path, new_path)

func remove_image(image_hash: String) -> void:
	if !_db.has(image_hash):
		return
	_db.erase(image_hash)

#region image data
func get_images() -> PackedStringArray:
	return _db.keys()

func has(image_hash: String) -> bool:
	return _db.has(image_hash)

func get_image_data(image_hash: String) -> ImageData:
	if image_hash in _db:
		return _db[image_hash].duplicate()
	return ImageData.new()

func get_path_for_hash(image_hash: String) -> String:
	if _db.has(image_hash):
		return get_image_data(image_hash).last_path
	return ""

#region serialization
func serialize() -> Dictionary:
	var data := {}
	for image_hash in _db:
		data[image_hash] = get_image_data(image_hash).serialize()
	return data

func deserialize(data: Dictionary) -> void:
	for image_hash in data:
		var image_data := ImageData.new()
		image_data.deserialize(data[image_hash])
		_db[image_hash] = image_data
#endregion
