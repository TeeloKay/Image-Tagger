class_name NewTagDialog extends ConfirmationDialog

@onready var _error_label: Label = %ErrorLabel
@onready var _tag_input: LineEdit = %TagEdit
@onready var _color_selection: ColorPickerButton = %ColorPicker

var tag := &""
var tag_data: TagData = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_error_label.hide()
	tag_data = TagData.new()

	_tag_input.text_changed.connect(_on_tag_input_changed)
	_tag_input.text_submitted.connect(_on_tag_input_submitted)
	_tag_input.focus_exited.connect(_on_tag_input_focus_lost)

	_color_selection.color_changed.connect(_on_color_selection_changed)
	_color_selection.color = tag_data.color

func _on_tag_input_changed(text: String) -> void:
	if ProjectContext.current_project != null:
		get_ok_button().disabled =  _tag_input.text in ProjectContext.current_project.get_tags()

func _on_tag_input_submitted(text: String) -> void:
	_tag_input.text = ProjectTools.sanitize_tag(text)

func _on_color_selection_changed(color: Color) -> void:
	pass

func _on_tag_input_focus_lost() -> void:
	_tag_input.text = ProjectTools.sanitize_tag(_tag_input.text)
