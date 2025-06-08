class_name SearchController extends MenuController

@export var search_panel: SearchPanel

var _search_string := ""
var _tags: Array[StringName] = []

func _ready() -> void:
	super._ready()
	
	search_panel.tag_remove_pressed.connect(remove_tag)
	search_panel.tag_suggestion_pressed.connect(add_tag)
	search_panel.search_pressed.connect(search)
	search_panel.reset_pressed.connect(reset_query)

func _on_project_loaded() -> void:
	super._on_project_loaded()
	search_panel.clear()
	search_panel.set_available_tags(_project_data.get_tags())

func search() -> void:
	var query := SearchQuery.new()
	query.text = _search_string
	query.tags = _tags
	ProjectManager.search_images(query)

func reset_query() -> void:
	_search_string = ""
	_tags.clear()
	search_panel.clear_input()
	search_panel.clear_badges()

func _on_tag_removed(tag: StringName) -> void:
	if tag in _tags:
		_tags.erase(tag)
		search_panel.remove_tag(tag)

func remove_tag(tag: StringName) -> void:
	if !tag.is_empty() && tag in _tags:
		_tags.erase(tag)
		search_panel.remove_tag(tag)

func add_tag(tag: StringName) -> void:
	if tag && !tag in _tags:
		_tags.append(tag)
		var data: TagData = _project_data.get_tag_data(tag)
		search_panel.add_tag(tag, data.color)

func set_tag_suggestions(tags: Array[StringName]) -> void:
	search_panel.set_tag_suggestions(tags)
