@tool class_name TaggingEditor extends Control

#region Nodes
# Reference to the tag dropdown menu.
@onready var _tag_menu: MenuButton = %TagSelector
# Container that holds all active tag badges.
@onready var _tag_container: FlowContainer = %TagContainer
# Input field for typing a new tag.
@onready var _tag_input: LineEdit = %TagInput
# Button used to submit the typed tag.
@onready var _tag_submit: Button = %SubmitTag
# Button to apply the current tag changes.
@onready var _apply_button: Button = %Apply
# Button to discard tag changes.
@onready var _discard_button: Button = %Discard
#endregion

#region Exported Properties
# List of tag suggestions shown in the dropdown.
@export var tag_suggestions: Array[StringName] = []:
	set = set_tag_suggestions

# Text shown on the apply button.
@export var apply_button_text: String = "Apply":
	set = set_apply_button_text

# Text shown on the discard button.
@export var discard_button_text: String = "Discard":
	set = set_discard_button_text

# Enables or disables interaction with the tag editor.
@export var allow_input: bool = true:
	set = set_allow_input

# Enables or disables the apply & discard buttons.
@export var can_submit: bool = false:
	set = set_can_submit
#endregion

#region Internal Variables
# Preloaded scene used to create tag badges.
var _tag_badge_scene := preload("res://scenes/ui/tag_badge.tscn")
#endregion

#region Signals

## Emitted when the Apply button is pressed.
signal apply_pressed

## Emitted when the Discard button is pressed.
signal discard_pressed

## Emitted when the user selects a tag suggestion from the dropdown.
## The tag passed is the chosen `StringName`.
signal tag_add_requested(tag: StringName)

## Emitted when the user submits a custom tag string (via Enter or button).
## Use this to handle raw tag inputs before validating or normalizing them.
signal raw_tag_requested(tag: String)

## Emitted when a tag badge requests to be removed.
## The tag passed is the `StringName` associated with that badge.
signal tag_remove_request(tag: String)

#endregion

#region Built-in Callbacks
# Called when the node enters the scene tree.
func _ready() -> void:
	_apply_button.pressed.connect(func() -> void: apply_pressed.emit())
	_discard_button.pressed.connect(func() -> void: discard_pressed.emit())

	_tag_menu.get_popup().id_pressed.connect(_on_suggestion_pressed)
	_tag_input.text_changed.connect(_on_input_text_changed)
	_tag_input.text_submitted.connect(_on_input_text_submitted)
	_tag_submit.pressed.connect(_on_submit_pressed)
	_tag_menu.resized.connect(_on_tag_menu_resized)
#endregion

#region Public API

# Adds a tag badge to the UI with the given tag and color.
func add_active_tag(tag: StringName, color: Color) -> void:
	var badge := _tag_badge_scene.instantiate() as TagBadge
	_tag_container.add_child(badge, INTERNAL_MODE_BACK)
	badge.tag = tag
	badge.modulate = color
	badge.remove_requested.connect(func(t: StringName) -> void: tag_remove_request.emit(t))

# Clears all current tags from the UI.
func clear() -> void:
	for child in _tag_container.get_children(true):
		child.queue_free()

# Enables the editor for interaction.
func enable() -> void:
	allow_input = true

# Disables the editor to prevent interaction.
func disable() -> void:
	allow_input = false
#endregion

#region Private methods
func _repopulate_suggestion_popup() -> void:
	var popup := _tag_menu.get_popup()
	popup.clear()
	for tag in tag_suggestions:
		popup.add_item(tag)
#endregion

#region UI Callbacks

# Called when a suggestion from the dropdown is selected.
func _on_suggestion_pressed(id: int) -> void:
	if id < 0 || id >= tag_suggestions.size():
		return
	var tag := tag_suggestions[id]
	tag_add_requested.emit(tag)

# Enables/disables the submit button based on text presence.
func _on_input_text_changed(text: String) -> void:
	_tag_submit.disabled = text.length() == 0

# Called when Enter is pressed in the input field.
func _on_input_text_submitted(text: String) -> void:
	raw_tag_requested.emit(text)
	_tag_input.clear()

# Called when the submit button is pressed.
func _on_submit_pressed() -> void:
	_on_input_text_submitted(_tag_input.text)

# Called when the tag menu is resized
func _on_tag_menu_resized() -> void:
	_tag_menu.get_popup().size = Vector2i(int(_tag_menu.size.x), 200)
	_tag_menu.get_popup().max_size = Vector2i(int(_tag_menu.size.x), 200)
#endregion

#region Property Setters/Getters

func set_apply_button_text(text: String) -> void:
	if !is_node_ready():
		await ready
	apply_button_text = text
	_apply_button.text = text

func set_discard_button_text(text: String) -> void:
	if !is_node_ready():
		await ready
	discard_button_text = text
	_discard_button.text = text


func set_tag_suggestions(tags: Array[StringName]) -> void:
	if !is_node_ready():
		await ready
	tag_suggestions = tags
	_repopulate_suggestion_popup()

func set_allow_input(val: bool) -> void:
	allow_input = val
	if !is_node_ready():
		await ready
	_tag_menu.disabled = !allow_input
	_tag_submit.disabled = !allow_input
	_tag_input.editable = allow_input

func set_can_submit(val: bool) -> void:
	can_submit = val
	if !is_node_ready():
		await ready
	_apply_button.disabled = !can_submit
	_discard_button.disabled = !can_submit
#endregion
