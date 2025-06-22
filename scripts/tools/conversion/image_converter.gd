class_name ImageConverter extends Node

var strategy: ImageConversionStrategy = null:
	set = set_strategy

func _init(strategy: ImageConversionStrategy) -> void:
	self.strategy = strategy


func convert(input_path: String, output_path: String = "") -> String:
	if strategy == null:
		return ""
	if input_path.get_extension() == strategy.get_target_extension():
		return ""
	if output_path.is_empty():
		output_path = input_path.get_basename() + "." + strategy.get_target_extension()
		print("output: ", output_path)
	if strategy._convert(input_path,output_path) == OK:
		return output_path
	return ""


func set_strategy(strat: ImageConversionStrategy) -> void:
	strategy = strat
