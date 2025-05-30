class_name ImageHasher extends Node

var project_data: ProjectData
var _known_hashes: Dictionary[String,String] = {}

signal hash_computed(pash: String, hash: String)

func initialize(data: ProjectData) -> void:
	project_data = data

func hash_image(rel_path: String) -> String:
	var abs_path := project_data.to_abolute_path(rel_path)
	
	return _hash_file(abs_path)
	var image := Image.new()

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
