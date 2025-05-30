class_name TagEditor extends Control

const COL_NAME := 0
const COL_AMOUNT := 1
const COL_COLOR := 2

@onready var _tag_tree: Tree = %TagTree
@onready var _add_button: Button = %AddTag
@onready var _refresh_button: Button = %Refresh
@onready var _color_picker: ColorPickerPopup = %ColorPickerPopup

var _picker_icon := preload("res://assets/icons/ColorPick.svg")

@export var project_data: ProjectData

var _active_tag: StringName = &""
var _item_map: Dictionary[StringName, TreeItem] = {}

func _ready() -> void:
	ProjectManager.project_loaded.connect(enable)
	
	_build_tree()
	
	_add_button.disabled = true
	_add_button.pressed.connect(_on_add_tag)
	_tag_tree.button_clicked.connect(_on_tree_item_button_clicked)
	_color_picker.color_picked.connect(_on_color_changed)
	
	disable()

func enable() -> void:
	_add_button.disabled = false
	_refresh_button.disabled = false
	project_data = ProjectManager.current_project
	_item_map.clear()
	_refresh_tags()

func disable() -> void:
	_add_button.disabled = true
	_refresh_button.disabled = true

func _build_tree() -> void:
	_tag_tree.columns = 3
	_tag_tree.set_column_title(COL_NAME, "Tag")
	_tag_tree.set_column_title(COL_AMOUNT, "Occurences")
	_tag_tree.set_column_expand(COL_AMOUNT, false)
	_tag_tree.set_column_title(COL_COLOR, "Color")
	_tag_tree.set_column_expand(COL_COLOR, false)
	
	_tag_tree.set_column_custom_minimum_width(COL_AMOUNT,160)
	_tag_tree.set_column_custom_minimum_width(COL_COLOR,100)

func _refresh_tags() -> void:
	_tag_tree.clear()
	_item_map.clear()
	
	var tags := project_data.get_tags()
	var root := _tag_tree.create_item()
	for tag in tags:
		_add_tag_to_tree(tag, root)

func _add_tag_to_tree(tag: StringName, root: TreeItem) -> void:
	var tag_data = project_data.get_tag_data(tag)
	var item := _tag_tree.create_item(root)
	var occurences: int = tag_data.hashes.size()
	
	item.set_text(COL_NAME, tag)
	item.set_editable(COL_NAME, false)
	
	item.set_text(COL_AMOUNT, str(occurences))
	item.set_text_alignment(COL_AMOUNT,HORIZONTAL_ALIGNMENT_LEFT)
	
	item.set_custom_bg_color(COL_COLOR, tag_data.color)
	item.set_text(COL_COLOR, "#" + tag_data.color.to_html(false))
	item.add_button(COL_COLOR,_picker_icon)
		
	_item_map[tag] = item

func _on_add_tag() -> void:
	# TODO: system to add new custom tags into the system.
	pass

func _on_tree_item_button_clicked(item: TreeItem, column: int, _id: int, _mouse_button_index: int) -> void:
	if column != COL_COLOR:
		return
	_active_tag = StringName(item.get_text(COL_NAME))
	var current_color = item.get_custom_bg_color(COL_COLOR)
	_color_picker.set_color(current_color)
	_color_picker.popup_centered()

func _on_color_changed(color: Color) -> void:
	if _active_tag.is_empty():
		return
	var tag_data = project_data.get_tag_data(_active_tag)
	tag_data.color = color
	
	# update item in tree, if it exists.
	if _item_map.has(_active_tag):
		var item := _item_map[_active_tag]
		item.set_custom_bg_color(COL_COLOR, tag_data.color)
		item.set_text(COL_COLOR, "#" + tag_data.color.to_html(false))
	_refresh_tags()
	_active_tag = &""
	
	ProjectManager.save_current_project()

func _on_refresh_pressed() -> void:
	_refresh_tags()
