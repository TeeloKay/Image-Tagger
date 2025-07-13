class_name ImageData extends RefCounted

const LAST_PATH := "last_path"
const FINGERPRINT := "fingerprint"
const TAGS := "tags"
const FAVORITES := "favorites"

var last_path: String = ""
var fingerprint: String = ""
var tags: Array[StringName] = []
var favorited: bool = false

func _init() -> void:
	last_path = ""
	fingerprint = ""
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
		LAST_PATH: last_path,
		FINGERPRINT: fingerprint,
		TAGS: tags,
		FAVORITES: favorited
	}
	return dict

func deserialize(dict: Dictionary) -> void:
	last_path = dict.get(LAST_PATH, "")
	fingerprint = dict.get(FINGERPRINT, "")
	favorited = bool(dict.get(FAVORITES, false))
	for tag: StringName in dict[TAGS]:
		tags.append(StringName(tag))

func duplicate() -> ImageData:
	var copy := ImageData.new()
	copy.last_path = last_path
	copy.fingerprint = fingerprint
	copy.tags = tags.duplicate()
	copy.favorited = favorited
	return copy
