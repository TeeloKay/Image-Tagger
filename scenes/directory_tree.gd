class_name DirectoryTree extends Tree

@export var drag_preview_modulate: Color = Color(1, 1, 1, 0.75)

var _folder_drag_preview := preload("res://scenes/common/drag_and_drop/folder_drag_preview.tscn")

signal image_data_dropped(files: PackedStringArray, target_dir: String)
signal folder_data_dropped(old_path: String, new_path: String)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is ImageDragData || data is FolderDragData

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var target := get_item_at_position(at_position)
	if target == null:
		return
	
	var target_path: String = target.get_metadata(0)
	
	if data is ImageDragData:
		image_data_dropped.emit(data.files, target_path)
		return
	if data is FolderDragData:
		folder_data_dropped.emit(target_path, data.directory)
		return


#region Drag and drop
func _get_drag_data(at_position: Vector2) -> Variant:
	var source := get_item_at_position(at_position)
	if source == null:
		return null
	
	var directory: String = source.get_metadata(0)
	var data := FolderDragData.new(directory)
	_build_drag_preview(directory)
	return data

func _build_drag_preview(directory: String) -> void:
	var preview: FolderDragPreview = _folder_drag_preview.instantiate()
	preview.text = directory.get_file()
	preview.modulate = drag_preview_modulate
	preview.pivot_offset = preview.size / 2
	set_drag_preview(preview)
	
#endregion
