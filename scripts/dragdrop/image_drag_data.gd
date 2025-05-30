class_name ImageDragData extends RefCounted

var type: String = "image"
var path: String = ""
var origin: Control

func _init(origin: Control, path: String):
	self.origin = origin
	self.path = path
