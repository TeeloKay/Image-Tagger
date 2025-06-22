class_name ImageMenuController extends MenuController

@export var image_view: ImageDataView

@export_global_file var current_image: String = ""
@export var _current_hash: String

@export var _working_tags: Array[StringName] = []
@export var _original_tags: Array[StringName] = []

@export var _error_dialog: AcceptDialog

@export var file_menu_controller : FileMenuController

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	InputHandler.apply_changes.connect(apply_changes)

	image_view.tag_add_requested.connect(_on_add_tag_request)
	image_view.tag_remove_requested.connect(_on_remove_tag_request)
	image_view.save_pressed.connect(apply_changes)
	image_view.discard_pressed.connect(discard_changes)
	image_view.name_change_request.connect(_on_rename_image_request)
	image_view.open_in_explorer_pressed.connect(_on_explorer_button_pressed)
	image_view.open_image_request.connect(_on_open_image_request)

func _on_project_loaded() -> void:
	super._on_project_loaded()
	var tags := _project_data.get_tags()
	image_view.set_tag_suggestions(tags)

func set_image(path: String) -> void:
	if path.is_empty():
		clear()
	if path.is_absolute_path():
		if current_image == path:
			return
		current_image = path
		var _current_image = path
		_current_hash = _project_data.get_hash_for_path(path)

		var texture = ImageUtil.load_image(path)
		image_view.set_texture(texture)
		image_view.set_file_name(_current_image.get_file())
		image_view.current_hash = _current_hash
		image_view.current_image = current_image
		image_view.clear_tags()
		image_view.enable()

		_original_tags = _project_data.get_tags_for_hash(_current_hash).duplicate()
		_working_tags = _original_tags.duplicate()
		_working_tags.sort_custom(func(a,b): return String(a) < String(b))
		_populate_tag_list()
		image_view.mark_clean()

func _on_explorer_button_pressed() -> void:
	if current_image.is_empty():
		return
	var folder_path := current_image.get_base_dir()
	OS.shell_open(folder_path)

func _on_open_image_request() -> void:
	if current_image.is_empty():
		return
	OS.shell_open(current_image)

func apply_changes() -> void:
	_project_data.add_image(_current_hash, current_image)
	_project_data.set_tags_for_hash(_current_hash, _working_tags)
	_original_tags = _working_tags
	_populate_tag_list()
	image_view.mark_clean()

	ProjectManager.save_current_project()

func discard_changes() -> void:
	_working_tags = _original_tags.duplicate()
	_populate_tag_list()
	image_view.mark_clean()

func clear() -> void:
	_working_tags 	= []
	_original_tags 	= []
	current_image 	= ""
	_current_hash	= ""
	image_view.clear()

func _populate_tag_list() -> void:
	image_view.clear_tags()
	for tag in _working_tags:
		var data = _project_data.get_tag_data(tag)
		image_view.add_tag(tag,data.color)

func _on_add_tag_request(tag: String) -> void:
	if !tag in _working_tags && tag != "":
		var tag_data := _project_data.get_tag_data(tag)
		_working_tags.append(tag)
		image_view.add_tag(tag, tag_data.color)
		image_view.mark_dirty()

func _on_remove_tag_request(tag: StringName) -> void:
	if !tag in _working_tags:
		return
	_working_tags.erase(tag)
	_populate_tag_list()
	image_view.mark_dirty()

func _on_rename_image_request(new_file: String) -> void:
	var old_file := current_image.get_file()

	if new_file.get_extension() == "":
		new_file = new_file + "." + old_file.get_extension()
		print(new_file)
	
	var new_path := current_image.replace(old_file,new_file)
	
	if FileAccess.file_exists(new_path):
		_error_dialog.title = "File already exists."
		_error_dialog.dialog_text = "A file with this name already exists in this location."
		_error_dialog.popup()
		set_image(current_image)
		return
	
	if !new_file.is_valid_filename():
		_error_dialog.title = "Invalid filename"
		_error_dialog.dialog_text = "%s is not a valid filename." % new_file
		_error_dialog.popup()
		set_image(current_image)
		return
	
	if new_path.get_extension() != current_image.get_extension():
		_error_dialog.title = "Wrong file extension"
		_error_dialog.dialog_text = "The new file name has the wrong extension."
		_error_dialog.popup()
		set_image(current_image)
		return
	
	FileService.move_file(current_image, new_path)
	_project_data.image_db.update_image_path(_current_hash, _project_data.to_relative_path(new_path))
	set_image(new_path)
	file_menu_controller.update()
