class_name TagData extends RefCounted

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
		"color": color.to_html(false),
	 	"category": category,
	 	"description": description,
		"hashes": hashes
	}
	return dict

func deserialize(dict: Dictionary) -> void:
	color = Color.html("#" + dict["color"])
	category = dict["category"]
	description = dict["description"]
	hashes = dict.get("hashes",[])
