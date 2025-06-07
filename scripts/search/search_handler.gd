class_name SearchHandler extends RefCounted

var _next_handler: SearchHandler
var project_data: ProjectData

func search(query: SearchQuery, out_results: Array) -> void:
    pass

func set_next(handler: SearchHandler) -> SearchHandler:
    _next_handler = handler
    return handler
