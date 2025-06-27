class_name ImageDragData extends RefCounted

var files: PackedStringArray = []
var origin: Control

func _init(origin: Control, files: PackedStringArray):
	self.origin = origin
	self.files = files
