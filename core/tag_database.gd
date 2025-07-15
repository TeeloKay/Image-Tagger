class_name TagDB extends Object

const TAGS: String = "tags"

var _db: Dictionary[StringName, TagData] = {}

signal tags_changed
signal tag_added(tag: StringName)
signal tag_removed(tag: StringName)
signal tag_updated(tag: StringName)
signal cleared

func _init() -> void:
	_db = {}

func set_tag_list(tags: Dictionary) -> void:
	_db = tags
	tags_changed.emit()

func add_tag(tag: StringName) -> void:
	if !_db.has(tag):
		_db[tag] = TagData.new()
		tag_added.emit(_db[tag])

func add_hash_to_tag(hash_val: String, tag: StringName) -> void:
	add_tag(tag)
	_db[tag].add_hash(hash_val)
	tags_changed.emit()

func remove_hash_from_tag(hash_val: String, tag: StringName) -> void:
	if tag.is_empty() || !_db.has(tag):
		return
	_db[tag].remove_hash(hash_val)
	tags_changed.emit()

func get_tags() -> Array[StringName]:
	return _db.keys()

func get_tag_data(tag: StringName) -> TagData:
	return _db[tag] if _db.has(tag) else TagData.new()

func set_tag_color(tag: StringName, color: Color) -> void:
	if !_db.has(tag):
		return
	_db[tag].color = color
	tag_updated.emit(tag)

func remove_tag(tag: StringName) -> void:
	if !_db.has(tag):
		return
	_db.erase(tag)
	tag_removed.emit(tag)

func has(tag: StringName) -> bool:
	return _db.has(tag)

func clear() -> void:
	_db.clear()
	cleared.emit()

#region serialization
func serialize() -> Dictionary:
	var data := {}
	data[TAGS] = {}
	for tag in _db:
		data[TAGS][tag] = get_tag_data(tag).serialize()
	return data

func deserialize(data: Dictionary) -> void:
	if data.has(TAGS):
		for tag: StringName in data[TAGS]:
			var tag_data := TagData.new()
			tag_data.deserialize(data[TAGS][tag])
			_db[StringName(tag)] = tag_data
#endregion
