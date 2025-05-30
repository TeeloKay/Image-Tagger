class_name ImageHasher extends Node

var project_data: ProjectData
var _known_hashes: Dictionary[String,String] = {}

signal hash_computed(pash: String, hash: String)

func initialize(data: ProjectData) -> void:
	project_data = data

func hash_image(rel_path: String) -> String:
	var abs_path := project_data.to_abolute_path(rel_path)
	
	if rel_path in _known_hashes:
		return _known_hashes[rel_path]
	var image := Image.new()
	
	var err := image.load(abs_path)
	if err != OK:
		push_warning("Failed to load image for hashing: ", abs_path)
		return ""
		
	var file := FileAccess.open(abs_path,FileAccess.READ)
	var hash := file.get_sha256(abs_path)
	file.close()

	if !project_data.image_data.has(hash):
		project_data.add_image(hash,rel_path)
	_known_hashes[rel_path] = hash
	
	return hash
