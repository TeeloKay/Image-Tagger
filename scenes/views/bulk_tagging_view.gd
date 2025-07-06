class_name BulkTaggingView extends Control

@onready var _selection_label: Label = %SelectionSizeLabel
@onready var _tag_menu: MenuButton = %TagSelector
@onready var _tag_container: FlowContainer = %TagContainer
@onready var _tag_input: TagInputContainer = %TagInput
@onready var _apply_button: Button = %Apply
@onready var _discard_button: Button = %Discard

var _is_dirty: bool = false
var _tag_badge_scene = preload("res://scenes/ui/tag_badge.tscn")

@export var controller: BulkTaggingController
@export var tag_suggestions: Array[StringName] = []

signal tag_add_requested(tag: StringName)
signal tag_remove_requested(tag: StringName)
signal apply_tags_requested()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_button.pressed.connect(_on_apply_pressed)
	_discard_button.pressed.connect(_on_discard_pressed)

	_tag_menu.get_popup().id_pressed.connect(func(id): tag_add_requested.emit(tag_suggestions[id]))
	_tag_input.tag_entered.connect(_on_add_tag_request)

func set_tag_suggestions(tags: Array[StringName]) -> void:
	tag_suggestions = tags
	var popup = _tag_menu.get_popup()
	popup.clear()
	for tag in tag_suggestions:
		popup.add_item(tag)

func set_selection_size(size: int) -> void:
	_selection_label.text = str(size)

func add_tag(tag: StringName, color: Color) -> void:
		var tag_badge := _tag_badge_scene.instantiate() as TagBadge
		_tag_container.add_child(tag_badge)
		tag_badge.tag = tag
		tag_badge.remove_requested.connect(_on_remove_tag_request)
		tag_badge.modulate = color

func clear_tag_list() -> void:
	for tag_badge in _tag_container.get_children():
		tag_badge.queue_free()
	
func _on_apply_pressed() -> void:
	apply_tags_requested.emit()

func _on_discard_pressed() -> void:
	pass

func _on_remove_tag_request(tag: StringName) -> void:
	tag_remove_requested.emit(tag)

func _on_add_tag_request(tag: StringName) -> void:
	tag_add_requested.emit(tag)
