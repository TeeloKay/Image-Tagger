class_name ImageFormatDetector extends RefCounted

const PNG_BYTES: PackedByteArray = [0x89,0x50,0x4E,0x47, 0x0D, 0x0A, 0x1A, 0x0A]
const JPG_BYTES: PackedByteArray = [0xFF, 0xD8, 0xFF]
const GIF_BYTES: PackedByteArray = [0x47, 0x49, 0x46, 0x38]
const BMP_BYTES: PackedByteArray = [0x42, 0x4D]

func detect_image_format(path: String) -> String:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null:
		return ""
	
	var header := file.get_buffer(512)
	file.close()
	
	if match_signature(header,PNG_BYTES):
		return "png"
	if match_signature(header,JPG_BYTES):
		return "jpg"
	if match_signature(header, BMP_BYTES):
		return "bmp"
	if match_signature(header, GIF_BYTES):
		return "gif"
	if header.get_string_from_ascii().begins_with("RIFF"):
		if header.slice(8,12) == PackedByteArray("WEBP".to_ascii_buffer()):
			return "webp"
		return "riff"
	if header.get_string_from_utf8().strip_edges().begins_with("<svg"):
		return "svg"
	return ""

func match_signature(header: PackedByteArray, signature: PackedByteArray) -> bool:
	for i in signature.size():
		if header[i] != signature[i]:
			return false
	return true
