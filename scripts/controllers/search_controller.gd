class_name SearchController extends Node

@export var search_panel: SearchPanel

var _project_data: ProjectData
var _tag_badge_scene := preload("res://scenes/ui/tag_badge.tscn")

var _search_string := ""
var _inclusive_tags: Array[StringName] = []
var _exclusive_tags: Array[StringName] = []

func _ready() -> void:
    ProjectManager.project_loaded.connect(_on_project_loaded)
    search_panel.search_requested.connect(_on_search_requested)
    search_panel.tag_added.connect(_on_tag_added)
    search_panel.tag_removed.connect(_on_tag_removed)

func _on_project_loaded() -> void:
    _project_data = ProjectManager.current_project

func _on_search_requested() -> void:
    var query := SearchQuery.new()
    query.text = _search_string
    query.tags = _inclusive_tags
    ProjectManager.search(query)

func _on_tag_added(tag: StringName) -> void:
    var data := project_data.get_tag_data(tag)
    if !tag:
        return
    search_panel.add_tag(tag, color)
    if !tag in _inclusive_tags:
        _inclusive_tags.append(tag)

func _on_tag_removed(tag: StringName) -> void:
    if tag in _inclusive_tags:
        _inclusive_tags.erase(tag)

func reset() -> void:
    _search_string = ""
    _inclusive_tags.clear()
    _exclusive_tags.clear()