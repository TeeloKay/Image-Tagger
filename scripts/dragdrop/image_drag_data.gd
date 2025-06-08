class_name ImageDragData extends RefCounted

var file_path: String = ""
var origin: Control

func _init(origin: Control, path: String):
	self.origin = origin
	self.file_path = path
