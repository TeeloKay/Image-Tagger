class_name QueueItem extends Object

var file: String
var tags: Array[StringName]

func _init(_file: String, _tags: Array[StringName]) -> void:
	self.file = _file
	self.tags = _tags
