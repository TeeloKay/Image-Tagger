class_name ImageDataView extends VSplitContainer

@onready var file_name_label: Label = %FileName
@onready var image_preview: TextureRect = %ImagePreview
@onready var explorer_button: Button = %ExplorerButton

@onready var _tag_container: FlowContainer = %TagContainer
@onready var _tag_input: TagInputContainer = %TagInputContainer

@onready var _save_button: Button = %ApplyButton
@onready var _discard_button: Button = %DiscardButton
@onready var _tag_picker: MenuButton = %MenuButton

@export var current_image: String = ""
@export var current_hash: String = ""


var _is_dirty: bool = false
var _tag_badge_scene = preload("res://scenes/ui/tag_badge.tscn")
var _tag_suggestions: Array[StringName]

signal explorer_button_pressed
signal tag_remove_requested(tag: StringName)
signal tag_add_requested(tag: StringName)
signal dirty_changed(is_dirty: bool)
signal save_pressed
signal discard_pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	explorer_button.pressed.connect(_on_explorer_button_pressed)
	_tag_input.tag_entered.connect(_on_add_tag_request)
	_save_button.pressed.connect(func(): save_pressed.emit())
	_discard_button.pressed.connect(func(): discard_pressed.emit())
	_tag_picker.get_popup().id_pressed.connect(_on_tag_menu_id_pressed)

	_tag_picker.get_popup().max_size = Vector2i(_tag_picker.size.x,200)
	_tag_picker.get_popup().size = Vector2i(_tag_picker.size.x, 200)


	explorer_button.disabled = true
	_save_button.disabled = true
	_discard_button.disabled = true

func set_texture(texture: Texture2D) -> void:
	image_preview.texture = texture

func set_file_name(file_name: String) -> void:
	file_name_label.text = file_name

func add_tag(tag: StringName, color: Color) -> void:
		var tag_badge := _tag_badge_scene.instantiate() as TagBadge
		_tag_container.add_child(tag_badge)
		tag_badge.tag = tag
		tag_badge.remove_requested.connect(_on_remove_tag_request)
		tag_badge.modulate = color

func set_tag_suggestions(tags: Array[StringName]) -> void:
	_tag_suggestions = tags
	var popup := _tag_picker.get_popup()
	popup.clear()
	if _tag_suggestions.is_empty():
		_tag_picker.disabled = true
		return
	for tag in _tag_suggestions:
		popup.add_item(tag)
	_tag_picker.disabled = false

func _on_tag_menu_id_pressed(id: int) -> void:
	var tag := _tag_suggestions[id]
	tag_add_requested.emit(tag)

func _on_explorer_button_pressed() -> void:
	explorer_button_pressed.emit()

func _on_remove_tag_request(tag: StringName) -> void:
	tag_remove_requested.emit(tag)

func _on_add_tag_request(tag: StringName) -> void:
	tag_add_requested.emit(tag)

func clear_tags() -> void:
	for child in _tag_container.get_children():
		child.queue_free()

func mark_clean() -> void:
	if _is_dirty:
		_is_dirty = false
		_save_button.disabled = true
		_discard_button.disabled = true
		dirty_changed.emit(_is_dirty)

func mark_dirty() -> void:
	if !_is_dirty:
		_is_dirty = true
		_save_button.disabled = false
		_discard_button.disabled = false
		dirty_changed.emit(_is_dirty)
