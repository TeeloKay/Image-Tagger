class_name ProjectToolbar extends BoxContainer

enum {
	MENU_NEW_PROJECT,
	MENU_OPEN_RECENT_PROJECT,
	MENU_CLEAR_INDEX,
	MENU_EXIT
}

@onready var file_dialog : FileDialog = %FileDialog
@onready var _file: PopupMenu = $FileMenuButton.get_popup()

var _recent_submenu: PopupMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	file_dialog.dir_selected.connect(_on_dialog_dir_selected)
	_build_menus()

func _build_menus():
	_file.clear()
	_file.add_item("New project", MENU_NEW_PROJECT)
	_recent_submenu = PopupMenu.new()
	_file.add_submenu_node_item("Open recent project", _recent_submenu, MENU_OPEN_RECENT_PROJECT)
	_file.add_separator()
	_file.add_item("Clear index", MENU_CLEAR_INDEX)
	_file.add_item("Exit", MENU_EXIT)
	
	var projects := ProjectManager.get_valid_projects()
	_file.set_item_disabled(MENU_OPEN_RECENT_PROJECT,projects.is_empty())
	for project in ProjectManager.get_valid_projects():
		_recent_submenu.add_item(project.replace(project.get_base_dir() + "/", ""))
	
	_file.id_pressed.connect(_on_file_menu_item_pressed)
	_recent_submenu.id_pressed.connect(_on_recent_menu_item_pressed)

func _on_file_menu_item_pressed(id: int) -> void:
	match id:
		MENU_NEW_PROJECT:
			_create_new_project()
		MENU_OPEN_RECENT_PROJECT:
			return
		MENU_CLEAR_INDEX:
			ProjectManager.current_project.clear_index()
		MENU_EXIT:
			get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
			get_tree().quit()
		_:
			return

func _on_recent_menu_item_pressed(id: int) -> void:
	var project := ProjectManager.get_valid_projects()[id]
	ProjectManager.open_project(project)

func _create_new_project() -> void:
	file_dialog.popup_centered()

func _on_dialog_dir_selected(dir: String) -> void:
	ProjectManager.open_project(dir)

func _on_rebuild_tags_pressed() -> void:
	pass
	#var images := ProjectManager.current_project.get_images()
	#for image in images:
		#var tags := ProjectManager.current_project.get_tags_for_image(image)
		#for tag in tags:
			#ProjectManager.current_project.add_tag(tag)
	#ProjectManager.save_current_project()
