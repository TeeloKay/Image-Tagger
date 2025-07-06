class_name QueueItem extends RefCounted

var file: String
var tags: Array[StringName]

func _init(file: String, tags: Array[StringName]) -> void:
	self.file = file
	self.tags = tags
