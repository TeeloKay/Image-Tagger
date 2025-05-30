class_name TagData extends RefCounted

var color: Color = Color.SLATE_GRAY
var category: String = ""
var description: String = ""
var hashes: PackedStringArray = []

func add_hash(hash: String) -> void:
	if hashes.has(hash):
		return
	hashes.append(hash)

func remove_hash(hash: String) -> void:
	var idx := hashes.find(hash)
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
