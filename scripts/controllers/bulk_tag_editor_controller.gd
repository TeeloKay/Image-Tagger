class_name BulkTagEditorController extends MenuController

@export var file_controller: FileMenuController
@export var image_view: ImageDataView

func _ready() -> void:
	super._ready()

	file_controller.selection_changed.connect(_on_selection_changed)


func _on_project_loaded() -> void:
	super._on_project_loaded()
	var tags := _project_data.get_tags()
	image_view.set_tag_suggestions(tags)
	image_view.enable()



func _on_selection_changed() -> void:
	var selection := file_controller.get_selection()
	if selection.size() == 1:
		print("one image selected")
		return
	print("more than one image selected")