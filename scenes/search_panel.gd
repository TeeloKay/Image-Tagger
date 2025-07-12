class_name SearchPanel extends VBoxContainer

var _active_tags: Dictionary[StringName, TagBadge]

var _tag_badge_scene := preload("res://scenes/ui/tag_badge.tscn")

@onready var _search_input: LineEdit = %SearchInput
@onready var _submit_button: Button = %SearchButton
@onready var _reset_button: Button = %ResetButton

@onready var _inclusive_menu: MenuButton = %InclusiveTagMenu
@onready var _inclusive_container: FlowContainer = %InclusiveTagContainer

@export var popup_max_height: int = 160

signal tag_remove_pressed(tag: StringName)
signal tag_suggestion_pressed(tag: StringName)
signal search_string_changed(string: String)
signal search_pressed
signal reset_pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_submit_button.pressed.connect(_on_search_pressed)
	_search_input.text_submitted.connect(_on_search)
	_reset_button.pressed.connect(_on_reset_pressed)
	_search_input.text_changed.connect(func(string: String) -> void: search_string_changed.emit(string))

	var popup := _inclusive_menu.get_popup()
	popup.id_pressed.connect(_on_inclusive_id_pressed)
	popup.max_size = Vector2i(_inclusive_menu.size.x, popup_max_height)

func _on_inclusive_id_pressed(id: int) -> void:
	var tag := _inclusive_menu.get_popup().get_item_text(id)
	if tag:
		tag_suggestion_pressed.emit(tag)

func display_tags(tags: Array[StringName]) -> void:
	clear_badges()
	for tag in tags:
		add_tag(tag, Color.SLATE_GRAY)

func add_tag(tag: StringName, color: Color) -> void:
	var badge := _tag_badge_scene.instantiate() as TagBadge
	_inclusive_container.add_child(badge)
	badge.set_tag(tag)
	badge.modulate = color
	badge.remove_requested.connect(func(t: StringName) -> void: tag_remove_pressed.emit(t))
	_active_tags[tag] = badge

func remove_tag(tag: StringName) -> void:
	if !_active_tags.has(tag):
		return
	_active_tags[tag].queue_free()

func _on_search(_query: String) -> void:
	_on_search_pressed()

func _on_search_pressed() -> void:
	search_pressed.emit()

func _on_reset_pressed() -> void:
	reset_pressed.emit()

func clear() -> void:
	clear_input()
	clear_badges()
	_inclusive_menu.get_popup().clear(true)
	
func set_available_tags(tags: Array[StringName]) -> void:
	var popup := _inclusive_menu.get_popup()
	popup.clear()
	for tag in tags:
		popup.add_item(tag)

func clear_input() -> void:
	_search_input.text = ""

func clear_badges() -> void:
	for tag in _active_tags:
		_active_tags[tag].queue_free()
	_active_tags = {}
