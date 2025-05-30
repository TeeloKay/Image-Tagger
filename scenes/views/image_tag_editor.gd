class_name ImageTagEditor extends Control

@onready var _tag_container: FlowContainer = %TagContainer
@onready var _tag_input: LineEdit = %TagInput
@onready var _add_tag_button: Button = %SubmitTag
@onready var _save_button: Button = %ApplyButton
@onready var _discard_button: Button = %DiscardButton

@export var project_data: ProjectData

@export var _working_tags: Array[StringName] = []
@export var _original_tags: Array[StringName] = []

var current_image_path: String:
	set = set_image_path
var current_image_hash: String
var _dirty: bool = false:
	set = _set_dirty

var _tag_badge_scene = preload("res://scenes/ui/tag_badge.tscn")

signal dirty_changed(is_dirty: bool)

func _ready() -> void:
	ProjectManager.project_loaded.connect(_initialize)
	project_data = ProjectManager.current_project
	
	_save_button.disabled = true
	_discard_button.disabled = true

func _initialize() -> void:
	project_data = ProjectManager.current_project

func set_image_path(path: String) -> void:
	current_image_path = path
	var hash := project_data.get_hash_for_path(path)
	_original_tags = project_data.get_tags_for_hash(hash).duplicate()
	_working_tags = _original_tags.duplicate()
	_refresh_tag_list()
	mark_clean()

func save_changes() -> void:
	project_data.add_image(current_image_hash, current_image_path)
	project_data.set_tags_for_hash(current_image_hash,_working_tags)
	_original_tags = _working_tags.duplicate()
	_refresh_tag_list()
	mark_clean()
	
	ProjectManager.save_current_project()

func discard_changes() -> void:
	_working_tags = _original_tags.duplicate()
	_refresh_tag_list()
	mark_clean()

#region Tags
func _on_add_tag_pressed() -> void:
	var text = _tag_input.text
	_on_add_tag(text)

func _on_add_tag(text: String) -> void:
	var tag := StringName(ProjectTools.sanitize_tag(text))
	if tag.is_empty() || tag in _working_tags:
		return
	_tag_input.clear()
	_working_tags.append(tag)
	_refresh_tag_list() 
	mark_dirty()

func _refresh_tag_list() -> void:
	for child in _tag_container.get_children():
		child.queue_free()
	
	for tag in _working_tags:
		var tag_badge := _tag_badge_scene.instantiate() as TagBadge
		_tag_container.add_child(tag_badge)
		tag_badge.tag = tag
		tag_badge.remove_requested.connect(_on_remove_tag)
		tag_badge.modulate = project_data.get_tag_data(tag).color

func _on_remove_tag(tag: StringName) -> void:
	_working_tags.erase(tag)
	_refresh_tag_list()
	mark_dirty()
	
#endregion
#region Dirt
func mark_dirty() -> void:
	_dirty = true

func mark_clean() -> void:
	_dirty = false

func is_dirty() -> bool:
	return _dirty

func _set_dirty(val: bool) -> void:
	#if _dirty == val:
		#return
	_dirty = val
	_save_button.disabled = !_dirty
	_discard_button.disabled = !_dirty
	dirty_changed.emit(_dirty)
#endregion
