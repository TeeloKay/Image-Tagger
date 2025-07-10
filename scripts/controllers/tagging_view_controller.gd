class_name TaggingViewController extends MenuController

@export var tagging_editor: TaggingEditor

@export_global_file var current_image: String = ""
@export var _current_hash: String

@export var _working_tags: Array[StringName] = []
@export var _original_tags: Array[StringName] = []

@export var _error_dialog: AcceptDialog
@export var file_menu_controller: FileBrowserController

var _file_hasher: ImageHasher
var _selection_index: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	InputHandler.apply_changes.connect(apply_changes)
	_file_hasher = ProjectManager.image_hasher

	tagging_editor.apply_pressed.connect(apply_changes)
	tagging_editor.discard_pressed.connect(discard_changes)
	tagging_editor.tag_add_requested.connect(_on_add_tag_request)
	tagging_editor.raw_tag_requested.connect(_on_raw_tag_request)
	tagging_editor.tag_remove_request.connect(_on_remove_tag_request)

	_file_hasher.file_hashed.connect(_on_file_hashed)

func _on_project_loaded() -> void:
	super._on_project_loaded()
	var tags := _project_data.get_tags()
	tagging_editor.set_tag_suggestions(tags)
	_project_data.tag_db.tag_added.connect(_update_tag_suggestions)

func set_image(path: String) -> void:
	if path.is_empty():
		clear()

	path = _project_data.to_abolute_path(path)
	if current_image == path:
		return

	current_image = path
	_file_hasher.add_file_to_queue(path)
	var texture = ImageUtil.load_image(path)

	tagging_editor.clear()

	tagging_editor.mark_clean()

func _on_open_image_request() -> void:
	if current_image.is_empty():
		return
	OS.shell_open(current_image)

func apply_changes() -> void:
	_project_data.add_image(_current_hash, current_image)
	_project_data.set_tags_for_hash(_current_hash, _working_tags)
	_original_tags = _working_tags
	_populate_tag_list()
	tagging_editor.mark_clean()

	ProjectManager.save_current_project()

func discard_changes() -> void:
	_working_tags = _original_tags.duplicate()
	_populate_tag_list()
	tagging_editor.mark_clean()

func clear() -> void:
	_working_tags = []
	_original_tags = []
	current_image = ""
	_current_hash = ""
	tagging_editor.clear()

func _populate_tag_list() -> void:
	tagging_editor.clear()
	for tag in _working_tags:
		var data = _project_data.get_tag_data(tag)
		tagging_editor.add_active_tag(tag, data.color)

func _on_add_tag_request(tag: StringName) -> void:
	if !tag in _working_tags && tag != "":
		var tag_data := _project_data.get_tag_data(tag)
		_working_tags.append(tag)
		tagging_editor.add_active_tag(tag, tag_data.color)
		tagging_editor.mark_dirty()

func _on_raw_tag_request(raw_tag: String) -> void:
	var tag := ProjectTools.sanitize_tag(raw_tag)
	_on_add_tag_request(tag)

func _on_remove_tag_request(tag: StringName) -> void:
	if !tag in _working_tags:
		return
	_working_tags.erase(tag)
	_populate_tag_list()
	tagging_editor.mark_dirty()

func _on_rename_image_request(new_file: String) -> void:
	var old_file := current_image.get_file()

	if new_file.get_extension() == "":
		new_file = new_file + "." + old_file.get_extension()
		print(new_file)
	
	var new_path := current_image.replace(old_file, new_file)
	
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

func _on_file_menu_controller_selection_changed() -> void:
	var selection := file_menu_controller.get_selection()
	if selection.is_empty():
		_selection_index = 0
		clear()
		return
	_selection_index = min(_selection_index, selection.size() - 1)
	set_image(selection[_selection_index])
			
func _on_file_hashed(path: String, file_hash: String) -> void:
	if path == current_image:
		_current_hash = file_hash

		_original_tags = _project_data.get_tags_for_hash(_current_hash).duplicate()
		_working_tags = _original_tags.duplicate()
		_working_tags.sort_custom(func(a, b): return String(a) < String(b))
		_populate_tag_list()

func _on_previous_pressed() -> void:
	var selection = file_menu_controller.get_selection()
	_selection_index = wrap(_selection_index - 1, 0, selection.size())
	set_image(selection[_selection_index])

func _on_next_pressed() -> void:
	var selection = file_menu_controller.get_selection()
	_selection_index = wrap(_selection_index + 1, 0, selection.size())
	set_image(selection[_selection_index])

func _update_tag_suggestions(_tag: StringName) -> void:
	var project_tags := _project_data.get_tags()
	tagging_editor.set_tag_suggestions(project_tags)
