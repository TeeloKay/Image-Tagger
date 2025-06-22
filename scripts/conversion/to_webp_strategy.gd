class_name ToWebPStrategy extends ImageConversionStrategy

var lossy: bool = false
var quality: float = 0.75
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _convert(input_path: String, output_path: String) -> void:
	var img := Image.new()
	var err := img.load(input_path)
	if err != OK:
		push_error("Failed to load image: %s" % err)
		return
	err = img.save_webp(output_path,lossy, quality)
	if err != OK:
		push_error("Failed to save PNG image: %s" % err)

func get_target_extension() -> String:
	return "webp"