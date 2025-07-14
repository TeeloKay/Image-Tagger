class_name DatabaseBridge extends Node

@export_global_file("*.db") var current_path: String

var _db: Node

signal database_loaded

func _ready() -> void:
	var node_script := load("res://scripts/database/DatabaseManager.cs")
	_db = node_script.new()
	add_child(_db, INTERNAL_MODE_BACK)

func open_database(path: String) -> void:
	if current_path == path:
		return
	ProjectSettings.globalize_path(path)
	current_path = path
	_db.SetDatabasePath(current_path)
	database_loaded.emit()

func add_image(img_hash: String, path: String, fingerprint: String, metadata: String = "{}") -> void:
	_db.AddImage(img_hash, path, fingerprint, metadata)

func add_tag(tag: StringName, color: Color) -> void:
	_db.AddTag(str(tag), color.to_html(false))

func tag_image(img_hash: String, tag: StringName) -> void:
	_db.TagImage(img_hash, tag)

func untag_image(img_hash: String, tag: StringName) -> void:
	_db.UntagImage(img_hash, tag)

func update_image_path(img_hash: String, new_path: String) -> void:
	_db.UpdateImagePath(img_hash, new_path)

func get_tags_for_image(img_hash: String) -> PackedStringArray:
	var result: Array[String] = _db.GetTagsForImage(img_hash)
	return PackedStringArray(result)

func get_image_info(img_hash) -> ImageData:
	var dict: Dictionary = _db.GetImageInfo(img_hash)
	if dict == null:
		return null

	var data := ImageData.new()
	data.last_path = dict.get("path", "")
	data.tags = _convert_tag_string(dict.get("tags", ""))
	data.fingerprint = dict.get("fingerprint", "")

	return data

func _convert_tag_string(tag_string: String) -> Array[StringName]:
	if tag_string.is_empty():
		return []
	
	var tags := tag_string.split("|", false)
	var tag_array: Array[StringName] = []
	for tag in tags:
		tag_array.append(StringName(tag))
	
	return tag_array
