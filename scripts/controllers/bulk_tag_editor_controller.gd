class_name BulkTagEditorController extends MenuController

@export var browser_controller: FileBrowserController
@export var image_view: TaggingView

func _ready() -> void:
	super._ready()
	# browser_controller.selection_changed.connect(_on_selection_changed)


func _on_project_loaded() -> void:
	super._on_project_loaded()
	var tags := _project_data.get_tags()
	image_view.set_tag_suggestions(tags)
	image_view.enable()


func _on_selection_changed() -> void:
	var selection := browser_controller.get_selection()
	if selection.size() == 1:
		print("one image selected")
		print(selection[0])
		return
	print("more than one image selected")
	for item in selection:
		print(item)
