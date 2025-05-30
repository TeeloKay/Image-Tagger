class_name FileListView extends Control

@onready var _list_view : ItemList = %ImageList
@onready var _context_menu: PopupMenu = %ContextMenu

var _current_dir: String = ""
var _file_paths_in_dir: PackedStringArray = []
var _right_click_index: int = -1

var _cache: ThumbnailCache

signal image_selected(image_path: String)

func _ready() -> void:
	_cache = ProjectManager.thumbnail_cache
	FileService.file_moved.connect(_on_file_moved)
	FileService.file_removed.connect(_on_file_removed)
	_build_context_menu()

func load_images_in_folder(directory_path: String) -> void:
	_current_dir = directory_path
	_list_view.clear()
	_file_paths_in_dir.clear()
	
	var dir = DirAccess.open(directory_path)
	if !dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():
			var ext := file_name.get_extension()
			var full_path := directory_path.path_join(file_name)
			if !ext in ImageUtil.ACCEPTED_TYPES:
				file_name = dir.get_next()
				continue
			_add_image_to_list(full_path, file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func load_images(image_paths: PackedStringArray) -> void:
	_list_view.clear()
	_file_paths_in_dir.clear()
	
	for path in image_paths:
		var full_path = _get_full_path(path)
		_add_image_to_list(full_path, path)

func refresh() -> void:
	if _current_dir:
		load_images_in_folder(_current_dir)
		return

func _add_image_to_list(full_path: String, file_name: String) -> void:
	var type := full_path.get_extension()
	var rel_path = _get_rel_path(full_path)
	var t := _cache.get_image(rel_path)
	if t == null:
		t = ImageUtil.generate_thumbnail_from_path(full_path)
		if t == null:
			return
	_cache.add_image(rel_path,t)
	
	var index := _list_view.add_item(file_name)
	_file_paths_in_dir.append(full_path)
	_list_view.set_item_icon(index,t)

func _get_full_path(rel_path: String) -> String:
	return ProjectManager.current_project.to_abolute_path(rel_path)

func _get_rel_path(full_path: String) -> String:
	return ProjectManager.current_project.to_relative_path(full_path)

func _build_context_menu() -> void:
	if !_context_menu:
		return
	
	_context_menu.add_check_item("favorite",0)
	_context_menu.add_separator()
	_context_menu.add_item("Rename", 1)
	_context_menu.add_item("Delete", 2)
	
	_context_menu.id_pressed.connect(_on_context_menu_item_pressed)
	_list_view.gui_input.connect(_on_list_view_gui_input)

func _on_context_menu_item_pressed(id: int) -> void:
	if _right_click_index < 0 || _right_click_index >= _file_paths_in_dir.size():
		return
	
	var path = _file_paths_in_dir[_right_click_index]
	var hash := ProjectManager.current_project.get_hash_for_path(path)
	var is_favorited = ProjectManager.current_project.is_favorited(hash)
	
	match id:
		0:
			if ProjectManager.current_project.is_favorited(hash):
				ProjectManager.current_project.remove_from_favorites(hash)
				_context_menu.set_item_checked(0,false)
			else:
				ProjectManager.current_project.add_to_favorites(hash)
				_context_menu.set_item_checked(0,true)
			ProjectManager.save_current_project()
		1:
			# TODO: remake
			pass
		2: # TODO: delete
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
		var hash := ProjectManager.current_project.get_hash_for_path(path)
		var is_favorited = ProjectManager.current_project.is_favorited(hash)
		_context_menu.set_item_checked(0, is_favorited)
		_context_menu.popup(Rect2(get_global_mouse_position(), Vector2.ZERO))


func _on_item_selected(index: int) -> void:
	if index < 0 || index >= _file_paths_in_dir.size():
		return
	var path := _file_paths_in_dir[index]
	image_selected.emit(path)

func get_file_paths_in_dir() -> PackedStringArray:
	return _file_paths_in_dir.duplicate()

func _on_file_moved(from_path: String, to_path: String) -> void:
	if from_path in _file_paths_in_dir || to_path in _file_paths_in_dir:
		refresh()

func _on_file_removed(path: String) -> void:
	if path in _file_paths_in_dir:
		refresh()
