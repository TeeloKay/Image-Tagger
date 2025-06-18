class_name ImageDataView extends VSplitContainer

@onready var _name_edit: LineEdit 			= %FileName
@onready var _image_preview: TextureRect 	= %ImagePreview
@onready var _explorer_button: Button 		= %ExplorerButton

@onready var _tag_container: FlowContainer 	= %TagContainer
@onready var _tag_input: TagInputContainer 	= %TagInputContainer

@onready var _save_button: Button 			= %ApplyButton
@onready var _discard_button: Button 		= %DiscardButton
@onready var _tag_picker: MenuButton 		= %MenuButton

@export var current_image: String 			= ""
@export var current_hash: String 			= ""


var _is_dirty: bool = false
var _tag_badge_scene = preload("res://scenes/ui/tag_badge.tscn")
var _tag_suggestions: Array[StringName]

var _enabled: bool

signal name_change_request(name: String)
signal tag_remove_requested(tag: StringName)
signal tag_add_requested(tag: StringName)
signal dirty_changed(is_dirty: bool)
signal save_pressed
signal discard_pressed
signal open_in_explorer_pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_name_edit.text = ""

	_explorer_button.pressed.connect(_on_explorer_button_pressed)
	_tag_input.tag_entered.connect(_on_add_tag_request)
	_save_button.pressed.connect(func(): save_pressed.emit())
	_discard_button.pressed.connect(func(): discard_pressed.emit())
	_tag_picker.get_popup().id_pressed.connect(_on_tag_menu_id_pressed)

	_name_edit.text_submitted.connect(_on_name_change_request)

	_tag_picker.resized.connect(_on_tag_picker_resized)
	disable()

func enable() -> void:
	_enabled = true
	_explorer_button.disabled = !_enabled

func disable() -> void:
	_enabled = false
	_explorer_button.disabled = !_enabled
	_save_button.disabled = !_enabled
	_discard_button.disabled = !_enabled

func _input(event: InputEvent) -> void:
	if !_enabled:
		return
	if event.is_action_pressed("rename"):
		print("enabling rename logic")
		_name_edit.editable = true
		_name_edit.grab_focus()
		var name_length := current_image.get_file().get_basename().length()
		print(current_image.get_file())
		print(name_length)
		_name_edit.select(0,name_length)
		_name_edit.caret_column = name_length

func set_texture(texture: Texture2D) -> void:
	_image_preview.texture = texture

func set_file_name(file_name: String) -> void:
	_name_edit.text = file_name

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
	open_in_explorer_pressed.emit()

func _on_remove_tag_request(tag: StringName) -> void:
	tag_remove_requested.emit(tag)

func _on_add_tag_request(tag: StringName) -> void:
	tag_add_requested.emit(tag)

func clear_tags() -> void:
	for child in _tag_container.get_children():
		child.queue_free()

func clear() -> void:
	_image_preview.texture = null
	_name_edit.text = ""
	clear_tags()
	mark_clean()
	
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

func _on_tag_picker_resized() -> void:
	_tag_picker.get_popup().size = Vector2i(_tag_picker.size.x, 200)
	_tag_picker.get_popup().max_size = Vector2i(_tag_picker.size.x, 200)

func _on_name_change_request(new_name: String) -> void:
	name_change_request.emit(new_name)
	_name_edit.editable = false
