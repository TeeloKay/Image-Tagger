class_name SearchQuery extends RefCounted

var filter: String = ""
var inclusive_tags: Array[StringName] = []
var exclusive_tags: Array[StringName] = []

func is_empty() -> bool:
    if !filter.is_empty():
        return false
    if !inclusive_tags.is_empty():
        return false
    if !exclusive_tags.is_empty():
        return false
    return true