class_name ToJPGConverter extends ImageConverter

var jpeg_quality: float = 0.75

func convert(input_path: String, output_path: String) -> Error:
	var img := Image.new()
	var err := img.load(input_path)
	if err != OK:
		push_error("Failed to load image: %s" % err)
		return err
	err = img.save_jpg(output_path, jpeg_quality)
	if err != OK:
		push_error("Failed to save PNG image: %s" % err)
	return err

func get_target_extension() -> String:
	return "jpeg"
