class_name DirectoryBrowser extends Control

enum ContextActions {ADD, RENAME, DELETE}

var _folder_icon := preload("res://assets/icons/Folder.svg")

@onready var _tree: DirectoryTree = %DirectoryTree
@onready var _context_menu: PopupMenu = %ContextMenu
@onready var _filter_input: LineEdit = %DirectoryFilter

signal folder_selected(path: String)
signal image_data_dropped(files: PackedStringArray, target_dir: String)
signal folder_data_dropped(target_dir: String, source_dir: String)

signal update_request
signal create_subfolder_request
signal rename_request
signal delete_request

func _ready() -> void:
	_tree.set_column_expand(0, true)
	_tree.set_column_custom_minimum_width(0, 128)
	_tree.item_selected.connect(_on_item_selected)
	_tree.image_data_dropped.connect(_on_image_data_dropped)
	_tree.folder_data_dropped.connect(_on_folder_data_dropped)
	
	_context_menu.clear()
	_context_menu.add_item("New folder...", ContextActions.ADD)
	_context_menu.add_item("Rename...", ContextActions.RENAME)
	_context_menu.add_item("Delete", ContextActions.DELETE)
	
	_context_menu.id_pressed.connect(_on_context_menu_pressed)

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("update"):
		update_request.emit()

func filter_tree(filter: String) -> void:
	var root := _tree.get_root()
	filter = filter.to_lower().strip_edges().strip_escapes()
	_recursive_filter(root, filter)

func _recursive_filter(item: TreeItem, filter: String) -> bool:
	var has_match := false
	var child: TreeItem = item.get_first_child()

	while child:
		if _recursive_filter(child, filter):
			has_match = true
		child = child.get_next()
	
	var metadata: String = item.get_metadata(0)
	var matches_self := metadata.to_lower().contains(filter) || filter == ""
	item.visible = matches_self || has_match
	return item.visible

func build_directory_tree(path: String) -> void:
	var expanded := _get_expanded_paths()
	_tree.clear()
	var dir := DirAccess.open(path)
	if !dir:
		print(DirAccess.get_open_error())
		return

	var root := _tree.create_item()
	_build_tree_item(root, path)
	_load_directory_recursively(path, root)

	_restore_expanded_paths(expanded)
	root.collapsed = false
	folder_selected.emit(path)

func _load_directory_recursively(path: String, parent: TreeItem) -> void:
	var dir := DirAccess.open(path)
	if !dir:
		push_error("Could not open ", path, ": ", DirAccess.get_open_error())
		return
	
	dir.list_dir_begin()
	var dir_name := dir.get_next()
	while dir_name != "":
		var full_path := path.path_join(dir_name)
		if dir.current_is_dir() && !dir_name.begins_with("."):
			var item := _tree.create_item(parent)
			_build_tree_item(item, full_path)
			_load_directory_recursively(full_path, item)
		dir_name = dir.get_next()
	dir.list_dir_end()

func _build_tree_item(item: TreeItem, path: String) -> void:
	item.set_icon(0, _folder_icon)
	item.set_text(0, path.replace(path.get_base_dir() + "/", ""))
	item.set_metadata(0, path)
	item.set_collapsed_recursive(item != _tree.get_root())

func _on_item_selected() -> void:
	var selected_item := _tree.get_selected()
	if selected_item:
		var path: String = selected_item.get_metadata(0)
		folder_selected.emit(path)

func clear() -> void:
	_tree.clear()

# Handles direct UI input from the directory tree
func _on_directory_tree_gui_input(event: InputEvent) -> void:
	if event is InputEventKey && event.is_pressed():
		if event.is_action("delete"):
			delete_request.emit()
			return
		if event.is_action("rename"):
			rename_request.emit()
			return
		return

	if event is InputEventMouseButton && event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var click_pos: Vector2 = event.position
			var item := _tree.get_item_at_position(click_pos)
			
			if item:
				_show_context_menu(item, event.global_position)

func _show_context_menu(_item: TreeItem, pos: Vector2) -> void:
	_context_menu.position = pos
	_context_menu.popup()
	
func _on_image_data_dropped(files: PackedStringArray, target_dir: String) -> void:
	image_data_dropped.emit(files, target_dir)

func _on_folder_data_dropped(target_dir: String, source_dir: String) -> void:
	folder_data_dropped.emit(target_dir, source_dir)

func clear_filter() -> void:
	_filter_input.clear()

func _on_context_menu_pressed(id: int) -> void:
	match id:
		ContextActions.ADD:
			create_subfolder_request.emit()
		ContextActions.RENAME:
			rename_request.emit()
		ContextActions.DELETE:
			delete_request.emit()
		_:
			return

#region Expansion Logic
func _get_expanded_paths() -> PackedStringArray:
	var expanded_paths: PackedStringArray = []
	var root := _tree.get_root()
	if root:
		_collect_expanded_paths_recursive(root, expanded_paths)
	return expanded_paths

func _collect_expanded_paths_recursive(item: TreeItem, paths: PackedStringArray) -> void:
	if !item:
		return
	var path: String = item.get_metadata(0)
	if path is String && !item.is_collapsed():
		paths.append(path)
	var child := item.get_first_child()
	while child:
		_collect_expanded_paths_recursive(child, paths)
		child = child.get_next()

func _restore_expanded_paths(expanded_paths: PackedStringArray) -> void:
	var root := _tree.get_root()
	if root:
		_set_expanded_recursive(root, expanded_paths)

func _set_expanded_recursive(item: TreeItem, expanded_paths: PackedStringArray) -> void:
	if !item:
		return
	var path: String = item.get_metadata(0)
	if path is String:
		item.set_collapsed(!expanded_paths.has(path))
	var child := item.get_first_child()
	while child:
		_set_expanded_recursive(child, expanded_paths)
		child = child.get_next()
#endregion
