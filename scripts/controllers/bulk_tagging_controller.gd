class_name BulkTaggingController extends MenuController

@export var browser_controller: FileBrowserController
@export var tagging_view: BulkTaggingView

@export var _selection: PackedStringArray
@export var active_tags: Array[StringName]:
	set = set_active_tags

@onready var tagging_queue: TaggingQueue = $TaggingQueue

signal active_tags_changed(tags: Array[StringName])

func _ready() -> void:
	super._ready()
	browser_controller.selection_changed.connect(_on_selection_changed)

	tagging_view.tag_add_requested.connect(_on_tag_add_request)
	tagging_view.tag_remove_requested.connect(_on_tag_remove_request)
	tagging_view.apply_tags_requested.connect(apply_tags_to_selection)

func _on_project_loaded() -> void:
	super._on_project_loaded()
	var tags := _project_data.get_tags()
	tagging_view.set_tag_suggestions(tags)
	tagging_queue.project_data = _project_data
	tagging_queue.image_hasher = ProjectManager.image_hasher

func _on_selection_changed() -> void:
	_selection = browser_controller.get_selection()
	tagging_view.set_selection_size(_selection.size())
	active_tags.clear()
	tagging_view.clear_tag_list()

func _on_tag_remove_request(tag: StringName) -> void:
	if !active_tags.has(tag):
		return
	active_tags.erase(tag)
	populate_tag_list(active_tags)

func _on_tag_add_request(tag: StringName) -> void:
	tag = ProjectTools.sanitize_tag(tag)
	if active_tags.has(tag):
		return
	active_tags.append(tag)
	populate_tag_list(active_tags)

func populate_tag_list(tags: Array[StringName]) -> void:
	tagging_view.clear_tag_list()
	for tag in tags:
		var data := _project_data.get_tag_data(tag)
		tagging_view.add_tag(tag, data.color)

func apply_tags_to_selection() -> void:
	for path in _selection:
		tagging_queue.enqueue(path, active_tags)
	tagging_queue.process_queue()
	active_tags.clear()

func set_active_tags(tags: Array[StringName]) -> void:
	active_tags = tags
	active_tags_changed.emit(active_tags)
