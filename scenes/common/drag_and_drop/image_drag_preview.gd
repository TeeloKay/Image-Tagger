class_name ImageDragPreview extends TextureRect

@onready var _panel: Panel = %Panel
@onready var _label: Label = %Label

var files: int = 0

func _ready() -> void:
	update()

func update() -> void:
	if files >= 1:
		_panel.show()
		_label.text = str(files)
		return
	_panel.hide()
