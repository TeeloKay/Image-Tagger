class_name TagInputContainer extends HBoxContainer
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

	_submit.disabled = _input.text == ""

func get_text() -> String:
	return _input.text

func set_text(text: String) -> void:
	_input.set_text(text)

func clear() -> void:
	_input.clear()
	cleared.emit()

func _on_text_changed(text: String) -> void:
	text_changed.emit(text)
	_submit.disabled = text == ""

func _on_submit_pressed() -> void:
	_on_text_submitted(_input.text)

func _on_text_submitted(text: String) -> void:
	var tag := ProjectTools.sanitize_tag(_input.text)
	tag_entered.emit(tag)
	clear()
