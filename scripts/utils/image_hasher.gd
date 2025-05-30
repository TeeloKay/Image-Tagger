class_name ImageHasher extends Node

var project_data: ProjectData
var _known_hashes: Dictionary[String,String] = {}

signal hash_computed(pash: String, hash: String)

func initialize(data: ProjectData) -> void:
	project_data = data

func hash_image(rel_path: String) -> String:
	var abs_path := project_data.to_abolute_path(rel_path)
	
	print("starting hashing of image: ", abs_path)
	if rel_path in _known_hashes:
		return _known_hashes[rel_path]
		
	var type = abs_path.get_extension()
	if type == "gif":
		return _hash_file(abs_path)
	var image := Image.new()
	
	var err := image.load(abs_path)
	if err != OK:
		push_warning("Failed to load image for hashing: ", abs_path)
		return ""
		
	var file := FileAccess.open(abs_path,FileAccess.READ)
	var hash := file.get_sha256(abs_path)
	file.close()

	if !project_data.image_manager.has(hash):
		project_data.add_image(hash,rel_path)
	_known_hashes[rel_path] = hash
	
	return hash

func _hash_file(path: String) -> String:
	if !FileAccess.file_exists(path):
		return ""
	
	var file := FileAccess.open(path,FileAccess.READ)
	if !file:
		return ""
	
	var bytes := file.get_buffer(file.get_length())
	file.close()
	
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	
	return ctx.finish().hex_encode()
	return ""
