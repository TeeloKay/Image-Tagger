class_name TagEditorController extends MenuController

@export var view: TagEditorView
@export var color_picker: ColorPickerPopup

var _active_tag: StringName = &""
var _item_map: Dictionary[StringName, TreeItem] = {}

func _ready() -> void:
	super._ready()

	view.refresh_pressed.connect(update_tags)
	view.tag_color_request.connect(_on_tag_color_request)
	
	color_picker.color_picked.connect(_on_color_changed)
	
func _on_project_loaded() -> void:
	super._on_project_loaded()
	enable()
	_item_map = {}
	_active_tag = &""
	update_tags()

func update_tags() -> void:
	view.clear()
	var tags := _project_data.get_tags()
	for tag in tags:
		add_tag_to_tree(tag)
	
func add_tag_to_tree(tag: StringName) -> void:
	var data := _project_data.get_tag_data(tag)
	var tree_item := view.add_tag_to_tree(tag, data)
	_item_map[tag] = tree_item

func update_tag(tag: StringName) -> void:
	var data = _project_data.get_tag_data(tag)


func _on_tag_color_request(item: TreeItem, _id: int, _mouse_button_index: int) -> void:
	_active_tag = StringName(item.get_metadata(0))
	var color := _project_data.get_tag_data(_active_tag).color
	color_picker.set_color(color)
	color_picker.popup_centered()

func _on_color_changed(color: Color) -> void:
	if _active_tag.is_empty():
		return
	var data := _project_data.get_tag_data(_active_tag)
	data.color = color

	update_tags()

func enable() -> void:
	view.enable()

func disable() -> void:
	view.disable()
