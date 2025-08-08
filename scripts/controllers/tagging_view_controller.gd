class_name TaggingViewController extends MenuController

enum Mode {NONE, SINGLE, BULK}

#region Exported Variables
@export var tagging_mode: Mode = Mode.NONE:
	set = set_tagging_mode
@export var tagging_editor: TaggingEditor

@export var file_menu_controller: FileBrowserController
@export var selection_manager: SelectionManager

@export_global_file var current_image: String = ""
@export var _current_hash: String

@export var _working_tags: Array[StringName] = []
@export var _original_tags: Array[StringName] = []
@export var _removed_tags: Array[StringName] = []
#endregion

#region Internal Variables
var _selection_index: int = 0
var _single_state: SingleTaggingState
var _bulk_state: BulkTaggingState
var _active_state: TaggingState
#endregion

#region signals
signal tagging_mode_changed(mode: Mode)
#endregion

#region Internal Callbacks
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()

	_single_state = SingleTaggingState.new(self)
	_bulk_state = BulkTaggingState.new(self)
	_change_state(_single_state)

	InputHandler.apply_changes.connect(apply_changes)

	if tagging_editor:
		tagging_editor.apply_pressed.connect(apply_changes)
		tagging_editor.discard_pressed.connect(discard_changes)
		tagging_editor.tag_add_requested.connect(_on_add_tag_request)
		tagging_editor.raw_tag_requested.connect(_on_raw_tag_request)
		tagging_editor.tag_remove_request.connect(_on_remove_tag_request)

	if selection_manager:
		selection_manager.selection_changed.connect(_on_selection_changed)

	ProjectManager.image_import_service.file_hashed.connect(_on_file_hashed)
	ProjectManager.database_adapter.tag_added.connect(_update_tag_suggestions)

func _on_project_loaded() -> void:
	super._on_project_loaded()
	_update_tag_suggestions()

#endregion

#region Public API
func set_image(path: String) -> void:
	if path.is_empty():
		clear()

	path = ProjectManager.to_abolute_path(path)
	if current_image == path:
		return

	current_image = path
	ProjectManager.image_import_service.add_file_to_queue(path)
	_update_tag_suggestions()

	tagging_editor.allow_input = true
	tagging_editor.can_submit = false

func apply_changes() -> void:
	_database.add_image(_current_hash, current_image, "", {})
	for tag in _working_tags:
		_database.add_tag(tag, Color.SLATE_GRAY)
	_database.multi_tag_image(_current_hash, _working_tags)
	for tag in _removed_tags:
		_database.untag_image(_current_hash, tag)
	_original_tags = _working_tags
	_removed_tags.clear()
	_populate_tag_list()

	tagging_editor.allow_input = true
	tagging_editor.can_submit = false

	ProjectManager.save_current_project()

func discard_changes() -> void:
	_working_tags = _original_tags.duplicate()
	_removed_tags.clear()
	_populate_tag_list()
	tagging_editor.allow_input = true
	tagging_editor.can_submit = false

func clear() -> void:
	_working_tags = []
	_original_tags = []
	_removed_tags = []
	current_image = ""
	_current_hash = ""
	tagging_editor.clear()

func set_tagging_mode(mode: Mode) -> void:
	tagging_mode = mode
	tagging_mode_changed.emit(mode)
	update_view()

func update_view() -> void:
	match tagging_mode:
		Mode.SINGLE:
			return
		Mode.BULK:
			return
#endregion

#region States
func _change_state(state: TaggingState) -> void:
	if _active_state != null:
		_active_state.exit()
	_active_state = state
	if _active_state != null:
		_active_state.enter()
#endregion

#region External Callbacks
## Opens image externally through an OS request
func _on_open_image_request() -> void:
	if current_image.is_empty():
		return
	OS.shell_open(current_image)

func _on_selection_changed() -> void:
	match selection_manager.get_selection_size():
		0:
			tagging_mode = Mode.NONE
			tagging_editor.can_submit = false
			tagging_editor.allow_input = false
		1:
			tagging_mode = Mode.SINGLE
			var selection := file_menu_controller.get_selection()
			_selection_index = min(_selection_index, selection.size() - 1)
			set_image(selection[_selection_index])
		_:
			tagging_mode = Mode.BULK
			var selection := file_menu_controller.get_selection()
			_selection_index = min(_selection_index, selection.size() - 1)
			set_image(selection[_selection_index])

func _on_add_tag_request(tag: StringName) -> void:
	if tag.is_empty():
		return
	if !tag in _working_tags && tag != "":
		var tag_data := _database.get_tag_info(tag)
		_working_tags.append(tag)
		tagging_editor.add_active_tag(tag, tag_data.color)
		tagging_editor.can_submit = true
		_update_tag_suggestions()
	if tag in _removed_tags:
		_removed_tags.erase(tag)

func _on_raw_tag_request(raw_tag: String) -> void:
	if raw_tag.is_empty():
		return
	var tag := ProjectTools.sanitize_tag(raw_tag)
	_on_add_tag_request(tag)

func _on_remove_tag_request(tag: StringName) -> void:
	if !tag in _working_tags:
		return
	_working_tags.erase(tag)
	_removed_tags.append(tag)
	_populate_tag_list()
	tagging_editor.can_submit = true

	_update_tag_suggestions()

func _on_file_hashed(path: String, file_hash: String) -> void:
	if path == current_image:
		_current_hash = file_hash
	print(path)
	_database.update_image_path(_current_hash, path)
	var tags := _database.get_tags_for_image(_current_hash)
	_original_tags.clear()
	for tag in tags:
		_original_tags.append(tag.tag)
	_working_tags = _original_tags.duplicate()
	_working_tags.sort_custom(func(a: String, b: String) -> bool: return String(a) < String(b))
	_populate_tag_list()
#endregion

#region UI Callbacks
func _populate_tag_list() -> void:
	tagging_editor.clear()
	for tag in _working_tags:
		var data := _database.get_tag_info(tag)
		tagging_editor.add_active_tag(tag, data.color)
	_update_tag_suggestions()
			

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

func _update_tag_suggestions() -> void:
	var tags: Array[StringName] = _database.get_all_tags().keys()
	for tag in _working_tags:
		tags.erase(tag)
	tagging_editor.set_tag_suggestions(tags)
