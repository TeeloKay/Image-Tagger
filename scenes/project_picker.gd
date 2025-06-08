class_name ProjectPicker extends Control

@export var file_dialog: FileDialog
@onready var project_list: ItemList = $MarginContainer/VBoxContainer/ItemList

signal project_selected(path: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_refresh_list()

func _refresh_list() -> void:
	for child in project_list.get_children():
		child.queue_free()
		
	for project in ProjectManager.get_valid_projects():
		var _idx := project_list.add_item(project)

func _on_new_project_pressed() -> void:
	file_dialog.show()

func _on_refresh_pressed() -> void:
	_refresh_list()

func _on_project_item_activated(index: int) -> void:
	project_selected.emit(ProjectManager.get_valid_projects()[index])

func _on_file_dialog_dir_selected(dir: String) -> void:
	ProjectManager.open_project(dir)
