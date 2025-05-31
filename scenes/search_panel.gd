class_name SearchPanel extends VBoxContainer

var _project_data: ProjectData
var _inclusive_tags: Array[StringName]
var _exclusive_tags: Array[StringName]

var _tag_badge_scene = preload("res://scenes/ui/tag_badge.tscn")

@onready var search_input: LineEdit = %SearchInput
@onready var search_button: Button = %SearchButton

@onready var _inclusive_menu: MenuButton = %InclusiveTagMenu
@onready var _inclusive_container: FlowContainer = %InclusiveTagContainer

signal results_ready(image_paths: PackedStringArray)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	search_button.pressed.connect(_on_search_pressed)
	search_input.text_submitted.connect(_on_search)
	_inclusive_menu.get_popup().id_pressed.connect(_on_inclusive_id_pressed)
	ProjectManager.project_loaded.connect(_on_project_loaded)

func _on_project_loaded() -> void:
	_project_data = ProjectManager.current_project
	var tags = _project_data.get_tags()
	var popup := _inclusive_menu.get_popup()
	popup.clear(true)
	for tag in tags:
		popup.add_item(tag)
	popup.max_size = Vector2i(_inclusive_menu.size.x, 160)

func _on_inclusive_id_pressed(id: int) -> void:
	var tag = _inclusive_menu.get_popup().get_item_text(id)
	if tag:
		if tag in _project_data.get_tags():
			if !tag in _inclusive_tags:
				_inclusive_tags.append(tag)
				refresh_tag_lists()

func _remove_inclusive_tag(tag: StringName) -> void:
	if _inclusive_tags.has(tag):
		_inclusive_tags.erase(tag)
		refresh_tag_lists()

func _remove_exclusive_tag(tag: StringName) -> void:
	if _exclusive_tags.has(tag):
		_exclusive_tags.erase(tag)
		refresh_tag_lists()

func refresh_tag_lists() -> void:
	for child in _inclusive_container.get_children():
		child.queue_free()
	
	for tag in _inclusive_tags:
		var badge := _tag_badge_scene.instantiate() as TagBadge
		_inclusive_container.add_child(badge)
		badge.set_tag(tag)
		badge.modulate = _project_data.get_tag_data(tag).color
		badge.remove_requested.connect(_remove_inclusive_tag)

func _on_search(_query: String) -> void:
	_on_search_pressed()

func _on_search_pressed() -> void:
	var query := SearchQuery.new()
	query.text = search_input.text
	query.tags = _inclusive_tags
	var results := ProjectManager.search_images(query)
	results_ready.emit(results)
