class_name ImageDragData extends RefCounted

var files: PackedStringArray = []
var source: Control

func _init(source: Control, files: PackedStringArray) -> void:
	self.source = source
	self.files = files
