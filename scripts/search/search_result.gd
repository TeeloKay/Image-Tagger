class_name SearchResult extends RefCounted

var image_path: String
var image_hash: String
var file_name: String
var score: float

func _init(path :String, hash_val: String) -> void:
    self.image_path = path
    self.image_hash = hash_val
    self.file_name = path.get_file()
    score = 1.0