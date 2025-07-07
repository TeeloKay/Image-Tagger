class_name BulkTaggingView extends Control

## Editing mode
enum Mode {NONE, SINGLE, BULK}

#region Nodes
@onready var _selection_label: Label = %SelectionSizeLabel
@onready var _previous_button: Button = %Previous
@onready var _next_button: Button = %Next

@onready var _tag_editor: TaggingEditor = %TaggingEditor
#endregion

#region Exported Properties
#endregion

#region signals
signal previous_pressed
signal next_pressed
#endregion

#region Built-in Callbacks
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_previous_button.pressed.connect(func(): previous_pressed.emit())
	_next_button.pressed.connect(func(): next_pressed.emit())
#endregion

#region Public API
func set_tag_suggestions(tags: Array[StringName]) -> void:
	_tag_editor.tag_suggestions = tags

func set_selection_size(selection_size: int) -> void:
	_selection_label.text = str(selection_size)

func add_tag(tag: StringName, color: Color) -> void:
	_tag_editor.add_active_tag(tag, color)

func clear_tag_list() -> void:
	_tag_editor.clear()

func get_tagging_editor() -> TaggingEditor:
	return _tag_editor
#endregion

#region UI Callbacks
#endregion
