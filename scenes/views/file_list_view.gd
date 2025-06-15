class_name FileListView extends Control

@onready var _refresh_button: Button = %RefreshButton
@onready var _list_view: ItemList = %ImageList
@onready var _context_menu: PopupMenu = %ContextMenu

var _current_dir: String = ""
var _file_paths_in_dir: PackedStringArray = []
var _right_click_index: int = -1

var _cache: ThumbnailCache
var _thumbnail_loader: ThumbnailLoader

signal item_selected(index: int)
signal multi_item_selected(index: int, selected: bool)
signal file_moved(from: String, to: String)
signal file_remove_request
signal file_rename_request
signal refresh_request

func _ready() -> void:
	_cache = ProjectManager.thumbnail_cache
	_thumbnail_loader = ThumbnailLoader.new()
	add_child(_thumbnail_loader, true, INTERNAL_MODE_BACK)

	_build_context_menu()

	_refresh_button.pressed.connect(_on_refresh_pressed)


func _on_thumbnail_ready(path: String, thumbnail: Texture2D) -> void:
	var index := _file_paths_in_dir.find(path)
	if index >= 0:
		set_item_thumbnail(index, thumbnail)

func set_item_thumbnail(index, thumbnail) -> void:
	_list_view.set_item_icon(index, thumbnail)

func refresh() -> void:
	pass

func add_item_to_list(full_path: String, file_name: String) -> int:
	var index := _list_view.add_item(file_name)
	_file_paths_in_dir.append(full_path)
	
	var rel_path := _get_rel_path(full_path)
	return index


func _build_context_menu() -> void:
	if !_context_menu:
		return
	
	_context_menu.add_check_item("favorite", 0)
	_context_menu.add_separator()
	_context_menu.add_item("Rename", 1)
	_context_menu.add_item("Delete", 2)
	
	_context_menu.id_pressed.connect(_on_context_menu_item_pressed)
	_list_view.gui_input.connect(_on_list_view_gui_input)

func clear() -> void:
	_file_paths_in_dir.clear()
	_list_view.clear()

func _on_context_menu_item_pressed(id: int) -> void:
	if _right_click_index < 0 || _right_click_index >= _file_paths_in_dir.size():
		return
	
	var path = _file_paths_in_dir[_right_click_index]
	var hash_val := ProjectManager.current_project.get_hash_for_path(path)
	
	match id:
		0:
			var is_fav = ProjectManager.current_project.is_favorited(hash_val)
			if is_fav:
				ProjectManager.current_project.remove_from_favorites(hash_val)
			else:
				ProjectManager.current_project.add_to_favorites(hash_val)
			_context_menu.set_item_checked(0, !is_fav)
			ProjectManager.save_current_project()
		1:
			file_rename_request.emit()
			pass
		2: 
			file_remove_request.emit()
			pass
		_:
			pass

func _on_list_view_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_MASK_RIGHT && event.is_pressed():
		var evt := event as InputEventMouseButton
		var click_pos := evt.position
		_right_click_index = _list_view.get_item_at_position(click_pos)
		
		if _right_click_index < 0 || _right_click_index >= _file_paths_in_dir.size():
			return
		
		var path = _file_paths_in_dir[_right_click_index]
		var hash_val := ProjectManager.current_project.get_hash_for_path(path)
		_context_menu.set_item_checked(0, ProjectManager.current_project.is_favorited(hash_val))
		_context_menu.popup(Rect2(get_global_mouse_position(), Vector2.ZERO))
	if event.is_action_pressed("delete"):
		file_remove_request.emit()
	if event.is_action_pressed("rename"):
		file_rename_request.emit()


func _on_item_selected(index: int) -> void:
	item_selected.emit(index)

func _on_image_list_multi_selected(index: int, selected: bool) -> void:
	multi_item_selected.emit(index, selected)

func _on_refresh_pressed() -> void:
	refresh_request.emit()

func get_file_paths_in_dir() -> PackedStringArray:
	return _file_paths_in_dir.duplicate()

func _on_file_moved(from_path: String, to_path: String) -> void:
	file_moved.emit(from_path, to_path)
	print("file moved")

func _on_file_removed(path: String) -> void:
	if path in _file_paths_in_dir:
		refresh()

func _get_full_path(rel_path: String) -> String:
	return ProjectManager.to_abolute_path(rel_path)

func _get_rel_path(full_path: String) -> String:
	return ProjectManager.to_relative_path(full_path)

func get_selected_items() -> PackedInt32Array:
	return _list_view.get_selected_items()
