class_name ProjectTools extends RefCounted

static func compute_hash_from_file(path: String) -> String:
	var image := Image.new()
	var err := image.load(path)
	
	if err != OK:
		push_warning("Failed to load image for hashing: ", path)
		return ""
		
	var file := FileAccess.open(path,FileAccess.READ)
	var hash := file.get_sha256(path)
	file.close()
	
	return hash

static func sanitize_tag(tag: String) -> String:
	return tag.strip_edges().to_lower().strip_escapes()
