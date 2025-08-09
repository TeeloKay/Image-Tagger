class_name TagEditorController extends MenuController

@export var view: TagEditorView
@export var color_picker: ColorPickerPopup

var _active_tag: StringName = &""
var _item_map: Dictionary[StringName, TreeItem] = {}

func _ready() -> void:
	super._ready()

	view.update_pressed.connect(update)
	view.tag_color_request.connect(_on_tag_color_request)
	view.tag_delete_request.connect(_on_tag_delete_request)
	
	color_picker.color_picked.connect(_on_color_changed)
	_database.tags_changed.connect(update)
	
func _on_project_loaded() -> void:
	super._on_project_loaded()
	enable()
	_item_map = {}
	_active_tag = &""
	update()

func update() -> void:
	view.clear()
	var tags := _database.get_all_tags()
	for tag in tags:
		add_tag_to_tree(tag)
	
func add_tag_to_tree(tag: StringName) -> void:
	var data := _database.get_tag_info(tag)
	var tree_item := view.add_tag_to_tree(tag, data)
	_item_map[tag] = tree_item

func update_tag(tag: StringName) -> void:
	var _data := _database.get_tag_info(tag)

func _on_tag_color_request(item: TreeItem, _id: int, _mouse_button_index: int) -> void:
	_active_tag = StringName(item.get_metadata(0))
	var color := _database.get_tag_info(_active_tag).color
	color_picker.set_color(color)
	color_picker.popup_centered()

func _on_tag_delete_request(item: TreeItem, _id: int, _mouse_button_index: int) -> void:
	if _mouse_button_index != MOUSE_BUTTON_LEFT: return
	var tag := StringName(item.get_metadata(0))
	print(tag)
	_database.delete_tag(tag)

func _on_color_changed(color: Color) -> void:
	if _active_tag.is_empty():
		return
	var data := _database.get_tag_info(_active_tag)
	ProjectContext.db.update_tag_color(_active_tag, color)
	data.color = color

	update()

func enable() -> void:
	view.enable()

func disable() -> void:
	view.disable()
