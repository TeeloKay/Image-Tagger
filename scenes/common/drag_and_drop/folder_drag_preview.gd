@tool class_name FolderDragPreview extends PanelContainer

@onready var _label: Label = %Label

var text: String:
	set = set_text
func _ready() -> void:
	update()

func update() -> void:
	_label.text = text

func set_text(txt: String) -> void:
	text = txt
	if !is_node_ready():
		await ready
	update()