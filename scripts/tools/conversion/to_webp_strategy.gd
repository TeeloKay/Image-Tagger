class_name ToWebPStrategy extends ImageConversionStrategy

var lossy: bool = false
var quality: float = 0.75

func _convert(input_path: String, output_path: String) -> Error:
	var img := Image.new()
	var err := img.load(input_path)
	if err != OK:
		push_error("Failed to load image: %s" % err)
		return err
	err = img.save_webp(output_path, lossy, quality)
	print(output_path)
	if err != OK:
		push_error("Failed to save PNG image: %s" % err)
	return err


func get_target_extension() -> String:
	return "webp"
