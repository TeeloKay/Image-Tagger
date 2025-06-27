class_name DirectoryTree extends Tree

signal data_dropped(files: PackedStringArray, target_dir: String)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var target := get_item_at_position(at_position)
	return data is ImageDragData && target != null

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var target := get_item_at_position(at_position)
	if target == null:
		return
	
	if data is ImageDragData:
		var to_path: String = get_item_at_position(at_position).get_metadata(0)
		data_dropped.emit(data.files, to_path)
