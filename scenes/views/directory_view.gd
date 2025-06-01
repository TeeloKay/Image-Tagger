class_name DirectoryView extends Control

var _folder_icon := preload("res://assets/icons/Folder.svg")
var _image_icon := preload("res://assets/icons/Image.svg")

@onready var _tree: DirectoryTree = %DirectoryTree
@onready var _context_menu: PopupMenu = %ContextMenu

signal folder_selected(path: String)

func _ready() -> void:
	ProjectManager.project_loaded.connect(_initialize)
	
	_tree.set_column_expand(0,true)
	_tree.set_column_custom_minimum_width(0,128)
	_tree.item_selected.connect(_on_item_selected)
	
	_context_menu.clear()
	_context_menu.add_item("Add folder", 0)
	_context_menu.add_item("Rename", 1)
	_context_menu.add_item("Delete",2)

func _initialize() -> void:
	var dir_path := ProjectManager.current_project.project_path
	_tree.clear()
	var dir: DirAccess = DirAccess.open(dir_path)
	if !dir:
		print(DirAccess.get_open_error())
		return
	var root = _tree.create_item()
	root.set_icon(0, _folder_icon)
	root.set_text(0,dir_path.replace(dir_path.get_base_dir() + "/", ""))
	root.set_metadata(0,dir_path)
	_load_directory_recursively(dir_path, root)
	folder_selected.emit(dir_path)

func _load_directory_recursively(path: String, parent: TreeItem) -> void:
	var dir := DirAccess.open(path)
	if !dir:
		push_error("Could not open ", path, ": ", DirAccess.get_open_error())
		return
	
	dir.list_dir_begin()
	var dir_name = dir.get_next()
	while dir_name != "":
		var full_path = path.path_join(dir_name)
		if !dir.current_is_dir() || dir_name.begins_with("."):
			dir_name = dir.get_next()
			continue
		var item = _tree.create_item(parent)
		item.set_icon(0, _folder_icon)
		item.set_text(0,dir_name)
		item.set_metadata(0,full_path)
		item.set_collapsed_recursive(true)
		_load_directory_recursively(full_path, item)
		dir_name = dir.get_next()
	dir.list_dir_end()

func _on_item_selected() -> void:
	var selected_item := _tree.get_selected()
	if selected_item:
		var path: String = selected_item.get_metadata(0)
		folder_selected.emit(path)

func clear() -> void:
	_tree.clear()

func _on_directory_tree_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var click_pos: Vector2 = event.position
			var item := _tree.get_item_at_position(click_pos)
			
			if item:
				_show_context_menu(item,click_pos)

func _show_context_menu(_item: TreeItem, pos: Vector2) -> void:
	_context_menu.position = pos
	_context_menu.popup()
	
