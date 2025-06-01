class_name ThumbnailLoader
extends Node

var _queue: Array[String] = []
var _cache: ThumbnailCache
@export_range(1,100,1) var _images_per_frame := 5

signal thumbnail_ready(path: String, thumbnail: Texture2D)

func _ready() -> void:
	_cache = ProjectManager.thumbnail_cache

func queue_thumbnail(path: String) -> void:
	if path in _queue:
		return
	_queue.append(path)

func _process(_delta: float) -> void:
	var processed := 0
	while processed < _images_per_frame && !_queue.is_empty():
		var path: String = _queue.pop_front()
		var rel_path := ProjectManager.current_project.to_relative_path(path)
		var thumbnail = _cache.get_image(rel_path)

		if thumbnail == null:
			thumbnail = ImageUtil.generate_thumbnail_from_path(path)
			if thumbnail:
				_cache.add_image(rel_path, thumbnail)
		
		if thumbnail:
			thumbnail_ready.emit(path, thumbnail)
		
		processed += 1

func rebuild_thumbnails(paths: PackedStringArray, clear_cache := true) -> void:
	if clear_cache:
		_cache.clear()
	for path in paths:
		queue_thumbnail(path)
