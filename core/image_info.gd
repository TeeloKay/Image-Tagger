class_name ImageInfo extends RefCounted

var last_path: String = ""
var tags: Array[StringName] = []
var favorited: bool = false

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
