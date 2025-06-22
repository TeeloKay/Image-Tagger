class_name ImageConverter extends Node

var strategy: ImageConversionStrategy = null:
	set = set_strategy

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _init(strategy: ImageConversionStrategy) -> void:
	self.strategy = strategy


func convert(input_path: String, output_path: String = "") -> void:
	if strategy == null:
		return
	if output_path.is_empty():
		output_path = input_path
		var input_ext := input_path.get_extension()
		output_path.replace(input_ext, strategy.get_target_extension())
	strategy._convert(input_path,output_path)


func set_strategy(strat: ImageConversionStrategy) -> void:
	strategy = strat