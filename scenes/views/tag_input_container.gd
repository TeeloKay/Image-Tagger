class_name TagInputContainer extends HBoxContainer

@export_range(1,20,1) var max_suggestions := 10

@onready var _input: LineEdit = %TagInput
@onready var _submit: Button = %SubmitTag

signal tag_entered(tag: StringName)
signal text_changed(text: String)
signal cleared

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_input.text_changed.connect(_on_text_changed)
	_input.text_submitted.connect(_on_text_submitted)
	_submit.pressed.connect(_on_submit_pressed)

func get_text() -> String:
	return _input.text

func set_text(text: String) -> void:
	_input.set_text(text)

func clear() -> void:
	_input.clear()
	cleared.emit()

func _on_text_changed(text: String) -> void:
	text_changed.emit(text)

func _on_submit_pressed() -> void:
	_on_text_submitted(_input.text)

func _on_text_submitted(text: String) -> void:

	var tag := ProjectTools.sanitize_tag(_input.text)
	tag_entered.emit(tag)
	clear()
