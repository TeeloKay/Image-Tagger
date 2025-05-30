class_name FileBrowser extends Node

@export var directory_view: DirectoryView
@export var file_list_view: FileListView
@export var image_view: ImageDataView

var current_open_folder: String = ""
var file_paths_in_dir : PackedStringArray = []

@export var _accepted_files: PackedStringArray

signal image_selected(image_path: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	directory_view.folder_selected.connect(_on_tree_item_selected)
	get_window().files_dropped.connect(_on_files_dropped)
	
	ProjectManager.project_loaded.connect(_on_project_loaded)

func _on_project_loaded() -> void:
	pass

func _on_tree_item_selected(path: String) -> void:
	file_list_view.load_images_in_folder(path)

# placeholder for future drag & drop from explorer functionality
func _on_files_dropped(files: PackedStringArray) -> void:
	print(files)

func _on_file_list_view_image_selected(image_path: String) -> void:
	pass
