class_name SearchController extends MenuController

@export var search_panel: SearchPanel

var _search_string := ""
var _tags: Array[StringName] = []

func _ready() -> void:
	super._ready()
	if search_panel:
		search_panel.tag_remove_pressed.connect(remove_tag)
		search_panel.tag_suggestion_pressed.connect(add_tag)
		search_panel.search_pressed.connect(search)
		search_panel.reset_pressed.connect(reset_query)
		search_panel.search_string_changed.connect(_on_search_string_changed)

func _on_project_loaded() -> void:
	super._on_project_loaded()
	search_panel.clear()
	search_panel.set_available_tags(_database.get_all_tags().keys())

func search() -> void:
	var query := SearchQuery.new()
	query.filter = _search_string.to_lower().strip_edges()
	query.inclusive_tags = _tags
	print(query)
	ProjectManager.search_files(query)

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
		var data: TagData = _database.get_tag_info(tag)
		search_panel.add_tag(tag, data.color)

func set_tag_suggestions(tags: Array[StringName]) -> void:
	search_panel.set_tag_suggestions(tags)

func _on_search_string_changed(string: String) -> void:
	_search_string = string
