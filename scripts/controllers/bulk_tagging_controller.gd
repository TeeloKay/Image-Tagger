class_name BulkTaggingController extends MenuController

@export var browser_controller: FileBrowserController
@export var selection_manager: SelectionManager
@export var tagging_editor: TaggingEditor

@export var _selection: PackedStringArray
@export var active_tags: Array[StringName]:
	set = set_active_tags

signal active_tags_changed(tags: Array[StringName])

func _ready() -> void:
	super._ready()
	if selection_manager:
		selection_manager.selection_changed.connect(_on_selection_changed)

	if tagging_editor:
		tagging_editor.apply_pressed.connect(apply_tags_to_selection)
		tagging_editor.discard_pressed.connect(_discard_changes)
		tagging_editor.tag_add_requested.connect(_on_tag_add_request)
		tagging_editor.raw_tag_requested.connect(_on_tag_add_request)
		tagging_editor.tag_remove_request.connect(_on_tag_remove_request)

		tagging_editor.can_submit = false
		tagging_editor.allow_input = true

func _on_project_loaded() -> void:
	super._on_project_loaded()
	var tags := _project_data.get_tags()
	tagging_editor.set_tag_suggestions(tags)

func _on_selection_changed() -> void:
	_selection = selection_manager.get_selection()
	tagging_editor.can_submit = selection_manager.get_selection_size() > 0
	# tagging_editor.set_selection_size(_selection.size())
	# active_tags.clear()
	# tagging_editor.clear()

func _on_tag_remove_request(tag: StringName) -> void:
	if !active_tags.has(tag):
		return
	active_tags.erase(tag)
	populate_tag_list(active_tags)

func _on_tag_add_request(tag: StringName) -> void:
	if tag.is_empty():
		return
	tag = ProjectTools.sanitize_tag(tag)
	if active_tags.has(tag):
		return
	active_tags.append(tag)
	populate_tag_list(active_tags)

func populate_tag_list(tags: Array[StringName]) -> void:
	tagging_editor.clear()
	for tag in tags:
		var data := _project_data.get_tag_data(tag)
		tagging_editor.add_active_tag(tag, data.color)

func apply_tags_to_selection() -> void:
	for path in _selection:
		ProjectManager.tagging_queue.enqueue(path, active_tags)
	active_tags.clear()
	tagging_editor.clear()

func _discard_changes() -> void:
	set_active_tags([])

func set_active_tags(tags: Array[StringName]) -> void:
	active_tags = tags
	active_tags_changed.emit(active_tags)
