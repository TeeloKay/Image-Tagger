class_name ImageConversionPopup extends Window

@onready var _progress_bar: ProgressBar = %"ProgressBar"
@onready var _label: Label = %"Label"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide()

func set_progress(progress: float) -> void:
	_progress_bar.value = progress

func set_text(text: String) -> void:
	_label.text = text

func update_progress(current_file: String, completed: int, total: int) -> void:
	_progress_bar.min_value = 0
	_progress_bar.max_value = total
	_progress_bar.value = completed
	_label.text = current_file.get_file()
