class_name ImageConverter extends Node

var strategies: Dictionary[String, ImageConversionStrategy] = {}

func _init() -> void:
	pass

func convert(type: String, input_path: String, output_path: String = "") -> String:
	if !strategies.has(type):
		return ""
	if input_path.get_extension() == strategies[type].get_target_extension():
		return ""
	if output_path.is_empty():
		output_path = input_path.get_basename() + "." + strategies[type].get_target_extension()
	if strategies[type]._convert(input_path, output_path) == OK:
		return output_path
	return ""


func add_strategy(type: String, strat: ImageConversionStrategy) -> void:
	strategies[type] = strat
