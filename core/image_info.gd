class_name ImageInfo extends RefCounted

var last_path: String = ""
var tags: Array[StringName] = []
var favorited: bool = false

func _init():
	last_path = ""
	tags = []
	favorited = false

func add_tag(tag: StringName) -> void:
	if tags.has(tag):
		return
	tags.append(tag)

func remove_tag(tag: StringName) -> void:
	if tags.has(tag):
		tags.erase(tag)

func serialize() -> Dictionary:
	var dict := {
		"last_path": last_path,
		"tags": tags,
		"favorited": favorited
	}
	return dict

func deserialize(dict: Dictionary) -> void:
	last_path = dict.get("last_path","")
	favorited = bool(dict.get("favorited",false))
	for tag in dict["tags"]:
		tags.append(StringName(tag))

func duplicate() -> ImageInfo:
	var dupe := ImageInfo.new()
	dupe.last_path = last_path
	dupe.tags = tags.duplicate()
	dupe.favorited = favorited
	return dupe