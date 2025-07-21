class_name TagEditorView extends Control

const COL_NAME := 0
const COL_AMOUNT := 1
const COL_COLOR := 2
const COL_SYNONYMS := 3

@onready var _tag_tree: Tree = %TagTree
@onready var _add_button: Button = %AddTag
@onready var _update_button: Button = %Update

var _picker_icon := preload("res://assets/icons/ColorPick.svg")

@export var project_data: ProjectData

signal tag_color_request(item: TreeItem, id: int, mouse_button_index: int)
signal update_pressed 

func _ready() -> void:
	_build_tree()
	_add_button.pressed.connect(_on_add_tag)
	_tag_tree.button_clicked.connect(_on_tree_item_button_clicked)
	_update_button.pressed.connect(_on_update_pressed)
	disable()

func enable() -> void:
	_add_button.disabled = false
	_update_button.disabled = false

func disable() -> void:
	_add_button.disabled = true
	_update_button.disabled = true

func _build_tree() -> void:
	_tag_tree.columns = 3
	_tag_tree.set_column_title(COL_NAME, "Tag")
	_tag_tree.set_column_title(COL_AMOUNT, "Occurences")
	_tag_tree.set_column_expand(COL_AMOUNT, false)
	_tag_tree.set_column_title(COL_COLOR, "Color")
	_tag_tree.set_column_expand(COL_COLOR, false)
	#_tag_tree.set_column_title(COL_SYNONYMS, "Synonyms")
	
	_tag_tree.set_column_custom_minimum_width(COL_AMOUNT,160)
	_tag_tree.set_column_custom_minimum_width(COL_COLOR,100)

func add_tag_to_tree(tag: StringName, data: TagData) -> TreeItem:
	var item := _tag_tree.create_item(_tag_tree.get_root())
	
	item.set_text(COL_NAME, tag)
	item.set_editable(COL_NAME, false)
	item.set_metadata(COL_NAME, tag)

	item.set_text(COL_AMOUNT, str(data.hashes.size()))
	item.set_text_alignment(COL_AMOUNT, HORIZONTAL_ALIGNMENT_LEFT)

	item.set_custom_bg_color(COL_COLOR, data.color)
	item.set_text(COL_COLOR, "#" + data.color.to_html(false))
	item.add_button(COL_COLOR,_picker_icon)

	return item

func clear() -> void:
	_tag_tree.clear()
	_tag_tree.create_item()

func _on_add_tag() -> void:
	# TODO: system to add new custom tags into the system.
	pass

func _on_tree_item_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match column:
		COL_COLOR:
			tag_color_request.emit(item,id,mouse_button_index)
		_:
			return

	
	ProjectManager.save_current_project()

func _on_update_pressed() -> void:
	update_pressed.emit()
