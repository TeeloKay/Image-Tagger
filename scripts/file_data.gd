class_name FileData extends RefCounted

var path: String
var modified: int
var size: int

func _init(path: String) -> void:
    self.path = path
    self.modified = 0
    self.size = 0

func get_extension() -> String:
    return path.get_extension()

func get_file() -> String:
    return path.get_file()