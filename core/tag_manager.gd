class_name TagManager extends Object

var _tag_db : Dictionary[StringName, TagData] = {}

signal tags_changed
signal tag_added(tag: StringName)
signal tag_removed(tag: StringName)
signal tag_updated(tag: StringName)

func _init() -> void:
	_tag_db = {}

func set_tag_list(tags: Dictionary) -> void:
	_tag_db = tags
	tags_changed.emit()

func add_tag(tag: StringName) -> void:
	if !_tag_db.has(tag):
		_tag_db[tag] = TagData.new()
		tag_added.emit(_tag_db[tag])

func add_hash_to_tag(hash_val: String, tag: StringName) -> void:
	add_tag(tag)
	_tag_db[tag].add_hash(hash_val)
	tags_changed.emit()

func remove_hash_from_tag(hash_val: String, tag: StringName) -> void:
	if tag.is_empty() || !_tag_db.has(tag):
		return
	_tag_db[tag].remove_hash(hash_val)
	tags_changed.emit()

func get_tags() -> Array[StringName]:
	return _tag_db.keys()

func get_tag_data(tag: StringName) -> TagData:
	return _tag_db[tag] if _tag_db.has(tag) else TagData.new()

func set_tag_color(tag: StringName, color: Color) -> void:
	if !_tag_db.has(tag):
		return
	_tag_db[tag].color = color
	tag_updated.emit(tag)

func has(tag: StringName) -> bool:
	return _tag_db.has(tag)
