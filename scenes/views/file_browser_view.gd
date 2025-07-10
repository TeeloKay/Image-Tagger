class_name FileBrowserView extends Control

enum IconSizes {SMALL, MEDIUM, LARGE}
enum {FAVORITE, RENAME, DELETE}

@export var _controller: FileBrowserController

@export_group("View settings")
@export var small := Vector2i(64, 64)
@export var medium := Vector2i(96, 96)
@export var large := Vector2i(128, 128)

@onready var _update_button: Button = %UpdateButton
@onready var _item_list: ResponsiveItemList = %ImageList
@onready var _context_menu: PopupMenu = %ContextMenu
@onready var _sort_menu: MenuButton = %SortButton
@onready var _type_filter_button: MenuButton = %TypeFilterButton
@onready var _file_count_label: Label = %FileCountLabel
@onready var _selection_count_label: Label = %SelectionCountLabel

var _file_paths_in_dir: PackedStringArray = []
var _right_click_index: int = -1

signal item_selected(index: int)
signal multi_item_selected(index: int, selected: bool)
signal file_moved(from: String, to: String)
signal file_remove_request
signal file_rename_request
signal update_request
signal selection_updated
signal sort_mode_changed(mode: int)
signal filter_item_pressed(id: int)

func _ready() -> void:
	_build_context_menu()
	_build_sort_menu()
	_build_type_filter_button()

	_update_button.pressed.connect(_on_update_pressed)
	_sort_menu.get_popup().id_pressed.connect(_on_sort_menu_item_pressed)

func update() -> void:
	pass

func add_item_to_list(full_path: String, file_data: FileData) -> int:
	var index: int = _item_list.add_item(full_path.get_file())
	_file_paths_in_dir.append(full_path)

	if file_data != null:
		var file_size := FileUtil.human_readable_size(file_data.size)
		var date := Time.get_datetime_string_from_unix_time(file_data.modified)
		var tooltip := "size: %s \nmodified: %s" % [file_size, date]
		_item_list.set_item_tooltip(index, tooltip)
	update_file_count(_item_list.item_count)

	return index

#region build toolbar 
func _build_context_menu() -> void:
	if !_context_menu:
		return
	
	_context_menu.add_check_item("Favorite", FAVORITE)
	_context_menu.add_separator()
	_context_menu.add_item("Rename", RENAME)
	_context_menu.add_item("Delete", DELETE)
	
	_context_menu.id_pressed.connect(_on_context_menu_item_pressed)
	_item_list.gui_input.connect(_on_list_view_gui_input)

func _build_sort_menu() -> void:
	if !_sort_menu:
		return
	var popup := _sort_menu.get_popup()
	for key: String in FileDataHandler.SortMode.keys():
		popup.add_radio_check_item(str(key).capitalize())

	var sort_mode := _controller.sort_mode
	popup.set_item_checked(sort_mode, true)

func _build_type_filter_button() -> void:
	if !_type_filter_button:
		return
	var popup := _type_filter_button.get_popup()
	popup.clear()
	for type in ImageUtil.ACCEPTED_TYPES:
		popup.add_check_item(type)
	
	popup.hide_on_checkable_item_selection = false
	popup.hide_on_item_selection = false
	popup.id_pressed.connect(_on_type_filter_button_item_pressed)
#endregion

func clear() -> void:
	_file_paths_in_dir.clear()
	_item_list.clear()

#region context logic
func _show_context_menu(click_position: Vector2) -> void:
	_right_click_index = _item_list.get_item_at_position(click_position)
	if _right_click_index < 0 || _right_click_index >= _file_paths_in_dir.size():
		return
		
	var path := _file_paths_in_dir[_right_click_index]
	var hash_val := ProjectManager.current_project.get_hash_for_path(path)
	_context_menu.set_item_checked(0, ProjectManager.current_project.is_favorited(hash_val))
	_context_menu.popup(Rect2(get_global_mouse_position(), Vector2.ZERO))

#TODO: move logic from this class to the file menu controller
func _on_context_menu_item_pressed(id: int) -> void:
	if _right_click_index < 0 || _right_click_index >= _file_paths_in_dir.size():
		return
	
	var path := _file_paths_in_dir[_right_click_index]
	var hash_val := ProjectManager.current_project.get_hash_for_path(path)
	
	match id:
		FAVORITE:
			var is_fav := ProjectManager.current_project.is_favorited(hash_val)
			if is_fav:
				ProjectManager.current_project.remove_from_favorites(hash_val)
			else:
				ProjectManager.current_project.add_to_favorites(hash_val)
			_context_menu.set_item_checked(0, !is_fav)
			ProjectManager.save_current_project()
		RENAME:
			file_rename_request.emit()
			pass
		DELETE:
			file_remove_request.emit()
			pass
		_:
			pass
#endregion


#region utility
func _get_full_path(rel_path: String) -> String:
	return ProjectManager.to_abolute_path(rel_path)

func _get_rel_path(full_path: String) -> String:
	return ProjectManager.to_relative_path(full_path)
#endregion

#region UI Callbacks
func _on_icon_size_button_item_selected(index: int) -> void:
	match index:
		IconSizes.SMALL:
			_item_list.set_icon_size(small)
		IconSizes.MEDIUM:
			_item_list.set_icon_size(medium)
		IconSizes.LARGE:
			_item_list.set_icon_size(large)
		_:
			_item_list.set_icon_size(medium)

func _on_sort_menu_item_pressed(id: int) -> void:
	var popup := _sort_menu.get_popup()
	for val in FileDataHandler.SortMode.values():
		popup.set_item_checked(val, val == id)
	sort_mode_changed.emit(id)

func _on_type_filter_button_item_pressed(id: int) -> void:
	var popup := _type_filter_button.get_popup()
	popup.toggle_item_checked(id)
	filter_item_pressed.emit(id)

func _on_item_selected(index: int) -> void:
	item_selected.emit(index)
	selection_updated.emit()

func _on_image_list_multi_selected(index: int, selected: bool) -> void:
	multi_item_selected.emit(index, selected)
	selection_updated.emit()

func _on_update_pressed() -> void:
	update_request.emit()
#endregion

func _on_thumbnail_ready(path: String, thumbnail: Texture2D) -> void:
	var index := _file_paths_in_dir.find(path)
	if index >= 0:
		set_item_thumbnail(index, thumbnail)

func _on_file_moved(from_path: String, to_path: String) -> void:
	file_moved.emit(from_path, to_path)
	print("file moved")

func _on_file_removed(path: String) -> void:
	if path in _file_paths_in_dir:
		update()

#endregion

#region Input Handlers
func _on_list_view_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MASK_RIGHT && event.is_pressed():
			var click_pos: Vector2 = event.position
			_show_context_menu(click_pos)
			return
		if event.button_index == MOUSE_BUTTON_MASK_LEFT && event.double_click:
			# TODO: put this logic in a more appropriate place.
			var index: int = _item_list.get_item_at_position(event.position)
			if index >= 0 && index < _item_list.item_count:
				var item := _file_paths_in_dir[index]
				OS.shell_open(item.get_base_dir())

	if event.is_action_pressed("delete"):
		file_remove_request.emit()
	if event.is_action_pressed("rename"):
		file_rename_request.emit()
	if event.is_action_pressed("select_all"):
		for i in _file_paths_in_dir.size():
			_item_list.select(i, false)
			selection_updated.emit()
	if event.is_action_pressed("ui_cancel"):
		_item_list.deselect_all()
		selection_updated.emit()

#endregion

#region getters & setters
func get_selected_items() -> PackedInt32Array:
	return _item_list.get_selected_items()

func set_item_thumbnail(index, thumbnail) -> void:
	_item_list.set_item_icon(index, thumbnail)

func get_file_paths_in_dir() -> PackedStringArray:
	return _file_paths_in_dir.duplicate()

func set_scroll_position(scroll_position: Vector2i) -> void:
	_item_list.get_h_scroll_bar().value = scroll_position.x
	_item_list.get_v_scroll_bar().value = scroll_position.y

func get_selected_item_paths() -> PackedStringArray:
	var items: PackedStringArray = []
	for index in get_selected_items():
		items.append(_file_paths_in_dir[index])
	return items
#endregion

func update_selection_count() -> void:
	_selection_count_label.text = str(_item_list.get_selected_items().size())

func update_file_count(count: int) -> void:
	_file_count_label.text = str(count)