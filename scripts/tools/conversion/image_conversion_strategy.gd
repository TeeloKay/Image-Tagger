class_name ImageConversionStrategy extends RefCounted


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _convert(_input_path: String, _output_path: String) -> Error:
	push_error("Convert() not implemented.")
	return ERR_UNAVAILABLE

func _is_compatible(_input_path: String) -> bool:
	return true

func get_target_extension() -> String:
	return ""