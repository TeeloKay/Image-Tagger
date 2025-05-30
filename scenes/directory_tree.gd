class_name DirectoryTree extends Tree

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var target := get_item_at_position(at_position)
	return data is ImageDragData && target != null

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var target := get_item_at_position(at_position)
	if target == null:
		return
	
	if data is ImageDragData:
		var to_path: String = get_item_at_position(at_position).get_metadata(0)
		var new_path := to_path.path_join(data.path.get_file())
		print(data.path, " -> ",new_path)
		ProjectManager.move_file(data.path,new_path)
