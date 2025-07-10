class_name TaggingViewController extends MenuController

enum Mode {NONE, SINGLE, BULK}

#region Exported Variables
@export var tagging_mode: Mode = Mode.NONE:
	set = set_tagging_mode
@export var tagging_editor: TaggingEditor

@export var file_menu_controller: FileBrowserController

@export_global_file var current_image: String = ""
@export var _current_hash: String

@export var _working_tags: Array[StringName] = []
@export var _original_tags: Array[StringName] = []
#endregion

#region Internal Variables
var _selection_index: int = 0
#endregion

#region signals
signal tagging_mode_changed(mode: Mode)
#endregion

#region Internal Callbacks
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	InputHandler.apply_changes.connect(apply_changes)

	if tagging_editor:
		tagging_editor.apply_pressed.connect(apply_changes)
		tagging_editor.discard_pressed.connect(discard_changes)
		tagging_editor.tag_add_requested.connect(_on_add_tag_request)
		tagging_editor.raw_tag_requested.connect(_on_raw_tag_request)
		tagging_editor.tag_remove_request.connect(_on_remove_tag_request)

	if file_menu_controller:
		file_menu_controller.selection_changed.connect(_on_selection_changed)

	ProjectManager.file_hasher.file_hashed.connect(_on_file_hashed)

func _on_project_loaded() -> void:
	super._on_project_loaded()
	var tags := _project_data.get_tags()
	tagging_editor.set_tag_suggestions(tags)
	_project_data.tag_db.tag_added.connect(_update_tag_suggestions)
#endregion

#region Public API
func set_image(path: String) -> void:
	if path.is_empty():
		clear()

	path = _project_data.to_abolute_path(path)
	if current_image == path:
		return

	current_image = path
	ProjectManager.file_hasher.add_file_to_queue(path)

	tagging_editor.clear()
	tagging_editor.mark_clean()

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

func set_tagging_mode(mode: Mode) -> void:
	tagging_mode = mode
	tagging_mode_changed.emit(mode)
	update_view()

func update_view() -> void:
	match tagging_mode:
		Mode.NONE:
			clear()
		Mode.SINGLE:
			return
		Mode.BULK:
			return
#endregion

#region External Callbacks
func _on_open_image_request() -> void:
	if current_image.is_empty():
		return
	OS.shell_open(current_image)

func _on_selection_changed() -> void:
	match file_menu_controller.get_selection_size():
		0:
			tagging_mode = Mode.NONE
		1:
			tagging_mode = Mode.SINGLE
		_:
			tagging_mode = Mode.BULK

func _on_add_tag_request(tag: StringName) -> void:
	if tag.is_empty():
		return
	if !tag in _working_tags && tag != "":
		var tag_data := _project_data.get_tag_data(tag)
		_working_tags.append(tag)
		tagging_editor.add_active_tag(tag, tag_data.color)
		tagging_editor.mark_dirty()

func _on_raw_tag_request(raw_tag: String) -> void:
	if raw_tag.is_empty():
		return
	var tag := ProjectTools.sanitize_tag(raw_tag)
	_on_add_tag_request(tag)

func _on_remove_tag_request(tag: StringName) -> void:
	if !tag in _working_tags:
		return
	_working_tags.erase(tag)
	_populate_tag_list()
	tagging_editor.mark_dirty()
#endregion

#region UI Callbacks
func _populate_tag_list() -> void:
	tagging_editor.clear()
	for tag in _working_tags:
		var data := _project_data.get_tag_data(tag)
		tagging_editor.add_active_tag(tag, data.color)

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

	tagging_editor.clear()
	_original_tags = _project_data.get_tags_for_hash(_current_hash).duplicate()
	_working_tags = _original_tags.duplicate()
	_working_tags.sort_custom(func(a: String, b: String) -> bool: return String(a) < String(b))
	_populate_tag_list()

func _update_tag_suggestions(_tag: StringName) -> void:
	var project_tags := _project_data.get_tags()
	tagging_editor.set_tag_suggestions(project_tags)

func _on_previous_pressed() -> void:
	var selection := file_menu_controller.get_selection()
	_selection_index = wrap(_selection_index - 1, 0, selection.size())
	set_image(selection[_selection_index])

func _on_next_pressed() -> void:
	var selection := file_menu_controller.get_selection()
	_selection_index = wrap(_selection_index + 1, 0, selection.size())
	set_image(selection[_selection_index])
#endregion


func _on_image_viewer_controller_selection_index_changed(index: int) -> void:
	_selection_index = index
