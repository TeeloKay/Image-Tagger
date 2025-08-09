class_name ProjectPicker extends Control

@export var file_dialog: FileDialog
@onready var project_list: ItemList = $MarginContainer/VBoxContainer/ItemList

signal project_selected(path: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_list()

func _update_list() -> void:
	for child in project_list.get_children():
		child.queue_free()
		
	for project in ProjectContext.get_valid_projects():
		var _idx := project_list.add_item(project)

func _on_new_project_pressed() -> void:
	file_dialog.show()

func _on_update_pressed() -> void:
	_update_list()

func _on_project_item_activated(index: int) -> void:
	project_selected.emit(ProjectContext.get_valid_projects()[index])

func _on_file_dialog_dir_selected(dir: String) -> void:
	ProjectContext.open_project(dir)
