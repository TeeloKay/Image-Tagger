class_name ImageDragData extends RefCounted

var type: String = "image"
var path: String = ""

func _init(path: String):
	self.path = path
