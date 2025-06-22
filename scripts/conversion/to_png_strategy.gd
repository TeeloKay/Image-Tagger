class_name ToPNGStrategy extends ImageConversionStrategy

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _convert(input_path: String, output_path: String) -> Error:
	var img := Image.new()
	var err := img.load(input_path)
	if err != OK:
		push_error("Failed to load image: %s" % err)
		return err
	err = img.save_png(output_path)
	print(output_path)
	if err != OK:
		push_error("Failed to save PNG image: %s" % err)
		return err
	return OK

	
func get_target_extension() -> String:
	return "png"