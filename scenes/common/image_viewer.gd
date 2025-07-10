@tool class_name ImageViewer extends Control

#region Nodes
@onready var _image_preview: TextureRect = %ImagePreview
@onready var _previous_button: Button = %Previous
@onready var _name_edit: LineEdit = %FileName
@onready var _next_button: Button = %Next
#endregion

#region signals
signal previous_pressed
signal next_pressed
signal image_double_clicked
signal name_submitted(name: String)
#endregion

#region Internal Callbacks
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_name_edit.text = ""
	_name_edit.editable = false

	_name_edit.text_submitted.connect(_on_name_text_submitted)
	_image_preview.gui_input.connect(_on_image_preview_gui_input)

	_next_button.pressed.connect(func() -> void: next_pressed.emit())
	_previous_button.pressed.connect(func() -> void: previous_pressed.emit())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		previous_pressed.emit()
		return
	if event.is_action_pressed("ui_right"):
		next_pressed.emit()
		return
	if event.is_action_pressed("rename"):
		_name_edit.editable = true
		_name_edit.grab_focus()
		var name_length := _name_edit.text.get_basename().length()
		_name_edit.select(0, name_length)
		_name_edit.caret_column = name_length
#endregion

#region Public API
func set_image_texture(texture: Texture2D) -> void:
	_image_preview.texture = texture

func set_file_name(file_name: String) -> void:
	_name_edit.text = file_name

func disable_directional_input() -> void:
	_previous_button.disabled = true
	_next_button.disabled = true

func enable_directional_input() -> void:
	_previous_button.disabled = false
	_next_button.disabled = false

func clear() -> void:
	_image_preview.texture = null
	_name_edit.text = ""
#endregion

#region UI Callbacks
func _on_name_text_submitted(new_name: String) -> void:
	name_submitted.emit(new_name)
	_name_edit.editable = false

func _on_image_preview_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.double_click && event.button_index == MOUSE_BUTTON_LEFT:
			image_double_clicked.emit()
#endregion