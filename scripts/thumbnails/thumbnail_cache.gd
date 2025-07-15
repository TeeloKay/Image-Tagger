class_name ThumbnailCache extends Node

var _cache: Dictionary[String,Texture2D] = {}
var max_cache_size := 200

func has(rel_path: String) -> bool:
	return _cache.has(rel_path)

func get_image(rel_path: String) -> Texture2D:
	return _cache.get(rel_path,null)

func add_image(rel_path: String, texture: Texture2D) -> void:
	_cache[rel_path] = texture

func clear() -> void:
	_cache.clear()
