extends Node

var _queue: Array[String]
var _cache: Dictionary[String,Texture2D] = {}

var images_per_frame: int = 5
var max_cache_size := 200

signal thumbnail_ready(path: String, thumbnail: Texture2D)

func has(rel_path: String) -> bool:
	return _cache.has(rel_path)

func get_image(rel_path: String) -> Texture2D:
	return _cache.get(rel_path,null)

func _add_image_to_cache(rel_path: String, texture: Texture2D) -> void:
	_cache[rel_path] = texture

func clear() -> void:
	_cache.clear()

func queue_thumbnail(abs_path: String) -> void:
	if abs_path in _queue:
		return
	_queue.append(abs_path)

func _process(_delta: float) -> void:
	var processed := 0
	while processed < images_per_frame && !_queue.is_empty():
		var path: String = _queue.pop_front()
		var thumbnail = get_image(path)

		if thumbnail == null:
			thumbnail = ImageUtil.generate_thumbnail_from_path(path)
			if thumbnail:
				_add_image_to_cache(path, thumbnail)
		
		if thumbnail:
			thumbnail_ready.emit(path, thumbnail)
		
		processed += 1

func rebuild_thumbnails(paths: PackedStringArray, clear_cache := true) -> void:
	if clear_cache:
		_cache.clear()
	for path in paths:
		queue_thumbnail(path)