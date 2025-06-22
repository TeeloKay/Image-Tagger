class_name ImageRepairTool extends Node

var png_bytes: PackedByteArray = [0x89,0x50,0x4E,0x47]
var jpg_bytes: PackedByteArray = [0xFF, 0xD8, 0xFF]
var webp_bytes: PackedByteArray = []

func detect_image_format(path: String) -> String:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null:
		return ""
	
	var header := file.get_buffer(16)
	file.close()
	
	if match_signature(header,png_bytes):
		return "png"
	if match_signature(header,jpg_bytes):
		return "jpg"
	if header.get_string_from_ascii().begins_with("RIFF"):
		return "webp"
	return ""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func match_signature(header: PackedByteArray, signature: PackedByteArray) -> bool:
	for i in signature.size():
		if header[i] != signature[i]:
			return false
	return true
