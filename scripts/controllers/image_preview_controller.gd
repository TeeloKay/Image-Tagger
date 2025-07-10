class_name ImagePreviewController extends MenuController

#region Exported Variables
@export var image_previewer: ImageViewer

@export var file_menu_controller: FileBrowserController
@export var file_renamer: FileRenamer

@export var selection_index: int = 0:
	set = set_selection_index
#endregion

#region Signals
signal selection_index_changed(index: int)
signal previous_pressed
signal next_pressed
#endregion

func _ready() -> void:
	super._ready()
	if image_previewer:
		image_previewer.previous_pressed.connect(_on_previous_pressed)
		image_previewer.next_pressed.connect(_on_next_pressed)
		image_previewer.name_submitted.connect(_on_rename_image_request)
		image_previewer.image_double_clicked.connect(_on_open_image_request)
	
	if file_menu_controller:
		file_menu_controller.selection_changed.connect(_on_selection_changed)

func _on_previous_pressed() -> void:
	_offset_selection_index(-1)
	update_view()

func _on_next_pressed() -> void:
	_offset_selection_index(1)
	update_view()

func _on_rename_image_request(new_name: String) -> void:
	var file := file_menu_controller.get_selection()[selection_index]
	var new_path := file.get_base_dir().path_join(new_name)
	await file_renamer.rename_file(file, new_path)
	file_menu_controller.update_view()
	update_view()

func _on_open_image_request() -> void:
	var current_image := file_menu_controller.get_selection()[selection_index]
	OS.shell_open(current_image)

func _on_selection_changed() -> void:
	update_view()

func _offset_selection_index(offset: int) -> void:
	var selection := file_menu_controller.get_selection()
	var selection_size := selection.size()
	selection_index = wrap(selection_index + offset, 0, selection_size)

func update_view() -> void:
	var selection := file_menu_controller.get_selection()
	if selection.is_empty():
		clear()
		return
	var image := selection[selection_index]
	image_previewer.set_image_texture(ImageUtil.load_image(image))
	image_previewer.set_file_name(image.get_file())

func set_selection_index(val: int) -> void:
	selection_index = val

func clear() -> void:
	image_previewer.clear()
	selection_index = 0
