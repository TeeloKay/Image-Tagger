class_name TagData extends RefCounted

const COLOR 		:= "color"
const CATEGORY 		:= "category"
const DESCRIPTION 	:= "description"
const HASHES 		:= "hashes"

var color: Color = Color.SLATE_GRAY
var category: String = ""
var description: String = ""
var hashes: PackedStringArray = []

func add_hash(hash_val: String) -> void:
	if hashes.has(hash_val):
		return
	hashes.append(hash_val)

func remove_hash(hash_val: String) -> void:
	var idx := hashes.find(hash_val)
	if idx >= 0:
		hashes.remove_at(idx)

func serialize() -> Dictionary:
	var dict := {
		COLOR: color.to_html(false),
	 	CATEGORY: category,
	 	DESCRIPTION: description,
		HASHES: hashes
	}
	return dict

func deserialize(dict: Dictionary) -> void:
	color = Color.html("#" + dict[COLOR])
	category = dict[CATEGORY]
	description = dict[DESCRIPTION]
	hashes = dict.get(HASHES,[])

func duplicate() -> TagData:
	var copy := TagData.new()
	copy.color = color
	copy.category = category
	copy.description = description
	copy.hashes = hashes
	return copy