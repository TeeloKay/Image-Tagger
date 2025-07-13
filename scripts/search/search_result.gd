class_name SearchResult extends RefCounted

var path: String
var image_hash: String
var file_name: String
## Score is a value from 0 - 1 representing the literal match between the search term and the file name/path.
var score: float

func _init(path :String, hash_val: String) -> void:
    self.path = path
    self.image_hash = hash_val
    self.file_name = path.get_file()
    score = 1.0