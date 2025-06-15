class_name ColorPickerPopup extends PopupPanel

@onready var _color_picker: ColorPicker = %ColorPicker
@onready var _submit_button: Button = %Submit
@onready var _cancel_button: Button = %Cancel

signal color_picked(color: Color)

@export_color_no_alpha var _initial_color: Color = Color.SLATE_GRAY

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_submit_button.pressed.connect(submit)
	_cancel_button.pressed.connect(cancel)
	_color_picker.color = _initial_color

func set_color(color: Color) -> void:
	_color_picker.color = color

func get_color() -> Color:
	return _color_picker.color

func submit() -> void:
	color_picked.emit(_color_picker.color)
	hide()
	pass

func cancel() -> void:
	hide()
	pass
