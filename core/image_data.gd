class_name ImageData extends RefCounted

var image_hash: String = ""
var last_path: String = ""
var fingerprint: String = ""
var tags: Array[StringName] = []
var favorited: bool = false

func add_tag(tag: StringName) -> void:
	if tags.has(tag):
		return
	tags.append(tag)

func remove_tag(tag: StringName) -> void:
	if tags.has(tag):
		tags.erase(tag)

func duplicate() -> ImageData:
	var copy := ImageData.new()
	copy.last_path = last_path
	copy.fingerprint = fingerprint
	copy.tags = tags.duplicate()
	copy.favorited = favorited
	return copy
