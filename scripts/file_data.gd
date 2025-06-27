class_name FileData extends RefCounted

var name: String
var modified: int
var size: int

func _init(name: String, modified: int, size: int) -> void:
    self.name = name
    self.modified = modified
    self.size = size